# Floreboard AI Proxy Architecture

## Product Position

Floreboard users should not configure LLM provider API keys, model names, or raw endpoints.
The iOS app should behave like a finished floristry product, not a developer console.

The server should be an AI orchestration backend, not a thin request forwarder. It owns provider
keys, model selection, prompt templates, retry policy, cost control, audit trails, and safety rules.
The iOS app owns user interaction, local inventory editing, image picking, local image caching, and
displaying generated results.

## Why Not Client-Side Keys

- User-facing API keys create setup friction before the first useful design.
- Keys on client devices are hard to rotate and easy to misuse.
- Model and provider changes would require App releases or hidden client configuration.
- There is no central place to rate limit, meter cost, inspect failures, or enforce store quotas.
- Prompt and provider-specific request formats become part of the mobile app contract.

## Target Flow

1. The user signs in with a store name or account identity.
2. The app sends structured design inputs to Floreboard backend.
3. The backend validates tenant entitlement, quota, and request shape.
4. The backend chooses the provider/model and builds prompts server-side.
5. The backend calls text, vision, and image models as needed.
6. The backend normalizes the provider response into a Floreboard response contract.
7. The app renders and locally saves the generated design result.

## iOS Responsibilities

- Capture occasion, style, budget, professional-mode fields, and optional reference image.
- Send current inventory snapshot with stable flower IDs, names, quantities, categories, and costs.
- Send language preference so generated user-facing text matches the UI.
- Render returned design result and preserve local history.
- Show product-level errors such as service unavailable, quota exceeded, or unsupported image.

The app must not send provider API keys, provider model names, raw OpenAI-compatible request bodies,
or provider-specific headers.

## Backend Responsibilities

- Store AI provider keys in server-side secrets management.
- Resolve tenant plan, quota, region, provider routing, and model fallback.
- Own system prompts and response-schema enforcement.
- Normalize provider failures into stable product errors.
- Track request IDs, latency, model cost, token/image usage, and failure reasons.
- Apply rate limits per tenant, user, and device.
- Keep raw provider payloads out of normal client responses.

## Cloudflare Deployment Constraints

The first backend target is Cloudflare Workers, so the proxy must be designed around edge runtime
limits instead of a traditional always-on server.

### Runtime Limits That Shape the Design

- Workers have a 128 MB memory limit per isolate. Do not buffer uploaded images, generated images,
  or provider responses in memory unless the payload is explicitly small and bounded.
- Worker request body limits depend on the Cloudflare account plan. As of the current Cloudflare
  Workers limits documentation, Free and Pro allow 100 MB request bodies, Business allows 200 MB,
  and Enterprise defaults to 500 MB. The app should still compress images aggressively and avoid
  sending large base64 payloads through JSON.
- CPU time is separate from wall-clock time. Waiting on provider `fetch()` calls does not count as
  CPU time, but JSON parsing, image decoding, prompt assembly over large payloads, and schema repair
  do. Keep Workers mostly as validators, orchestrators, and stream routers.
- HTTP Workers have no hard wall-clock duration while the client stays connected, but mobile clients
  should not be forced to wait through long image-generation polling. Use async jobs for slow paths.
- Queue consumers and Workflow steps have their own execution limits. They are better suited for
  long-running retries, image polling, provider fallback, and post-response persistence.

### Recommended Cloudflare Shape

Use a small set of Workers instead of one monolithic proxy:

1. `api-worker`: Authenticates the app, validates request size, enforces tenant limits, and creates
   design jobs.
2. `ai-worker`: Executes text and vision model calls through Cloudflare AI Gateway or direct provider
   SDK calls with server-side secrets.
3. `image-worker`: Issues R2 signed upload/download URLs and handles generated image callbacks or
   polling.
4. `queue-consumer` or `workflow`: Runs slow image generation, retries, fallback routing, and
   persistence outside the user request path.

Use Cloudflare bindings instead of calling Cloudflare REST APIs from inside Workers:

- R2 binding for reference uploads and generated images.
- D1 binding for request metadata, tenant usage counters, and design job status.
- Queue binding for slow generation jobs.
- Service bindings for Worker-to-Worker calls.
- Secrets for provider keys and Cloudflare AI Gateway tokens.

### Image Handling on Cloudflare

Do not send full-resolution reference images as base64 inside `/v1/designs/visual` JSON. Base64 adds
size overhead and encourages buffering. Prefer this flow:

1. App asks `POST /v1/uploads/reference-image` for an upload slot.
2. Worker creates an R2 object key and returns a short-lived signed upload URL.
3. App uploads compressed JPEG/HEIC directly to R2.
4. App calls `/v1/designs/visual` with `imageUploadId`.
5. Backend retrieves or streams the R2 object only when needed for the selected provider.

Generated images should also be stored in R2 and returned to the app as short-lived signed URLs. The
app may still cache the final image locally after download.

### AI Gateway Use

Cloudflare AI Gateway is useful for provider routing, metrics, retry policy, rate limiting, caching,
and log control. The backend should call AI Gateway, not the iOS app. Disable payload logging for
requests that may contain store inventory, customer context, or reference-image descriptions unless
support diagnostics explicitly require payload capture.

Recommended behavior:

- Keep provider keys in Cloudflare Secrets Store or Worker secrets.
- Use AI Gateway for cost and latency observability.
- Add gateway/provider timeout headers so slow providers fail predictably.
- Keep Floreboard's own product-level quota in D1 or a dedicated limiter; do not rely only on
  provider rate limits.

### Synchronous vs Asynchronous Endpoints

Use synchronous endpoints only for bounded text planning:

- `/v1/designs/plan` can be synchronous if it only performs one or two model calls and returns
  normalized JSON.
- `/v1/designs/visual` should usually create a job when a reference image is involved.
- `/v1/images/generate` should be asynchronous by default because image providers often require
  polling or take long enough that mobile clients may background the app.

Suggested async contract:

```json
{
  "jobId": "job-id",
  "status": "queued",
  "pollAfterSeconds": 2
}
```

Then:

- `GET /v1/jobs/{jobId}` returns `queued`, `running`, `succeeded`, or `failed`.
- `succeeded` includes the normalized `DesignResult` and any signed image URL.
- The app can poll conservatively while foregrounded and refresh status when reopened.

## Minimal API Contract

### `POST /v1/designs/plan`

Generates a design from structured user preferences and inventory.

Request:

```json
{
  "tenantId": "store-id",
  "language": "zh",
  "request": {
    "occasion": "wedding",
    "style": "modern",
    "budget": 500,
    "designMode": "quick",
    "school": null,
    "technique": null,
    "culturalContext": null,
    "scalePreference": "auto",
    "moodPreference": "auto",
    "formPreference": "auto",
    "backgroundStyle": "auto"
  },
  "inventory": [
    {
      "id": "flower-id",
      "name": "Rose",
      "color": "Red",
      "quantity": 24,
      "category": "main",
      "unitCost": 5.0,
      "retailPrice": 15.0,
      "meaning": "Love",
      "cultureTags": ["western"]
    }
  ]
}
```

Response:

```json
{
  "requestId": "server-request-id",
  "title": "Modern Ceremony Rose Arrangement",
  "description": "A concise client-facing design summary.",
  "meaningText": "Symbolic explanation.",
  "reasoning": "Short professional rationale.",
  "steps": ["Prepare stems", "Build focal shape"],
  "imagePrompt": "Optional backend-generated visual prompt",
  "estimatedCost": 180.0,
  "flowerList": [
    {
      "flowerName": "Rose",
      "count": 12,
      "reason": "Primary focal bloom"
    }
  ]
}
```

### `POST /v1/designs/visual`

Generates a design from a reference image plus the same structured fields as `/v1/designs/plan`.
The client should upload the compressed reference image to R2 first and pass an `imageUploadId`.
Inline base64 should be kept as a debug-only fallback for small images.

### `POST /v1/images/generate`

Generates a final image from a backend-approved prompt or design request ID.
Prefer accepting `requestId` over accepting arbitrary prompt text so the server remains the source
of truth for prompt policy.

Response should return either a short-lived image URL or base64 image data:

```json
{
  "requestId": "server-request-id",
  "imageUrl": "https://...",
  "imageBase64": null,
  "expiresAt": 1800000000
}
```

## Error Contract

Use stable product errors instead of raw provider errors:

- `service_unavailable`: AI service is temporarily unavailable.
- `quota_exceeded`: tenant has reached the usage limit.
- `invalid_inventory`: inventory payload cannot be used.
- `unsupported_image`: image is too large, corrupt, or unsupported.
- `generation_failed`: generation failed after provider fallback.

Each error response should include `requestId`, `code`, and localized-safe `message`.

## Migration Plan

1. Keep Settings free of provider/API-key controls.
2. Add a managed backend base URL to app configuration, controlled by build configuration or remote config.
3. Introduce an `AIProxyClient` that calls Floreboard endpoints and returns normalized response models. This client boundary now exists in `Floreboard/AIProxyClient.swift`.
4. Move prompt construction, provider headers, model IDs, and provider response parsing out of iOS.
5. Add R2 upload flow for reference images before enabling visual mode through the proxy.
6. Move image generation to async jobs backed by Queues or Workflows.
7. Keep the current direct-provider path only as an internal debug fallback, hidden from production UI.
8. Add backend quota, request logs, and provider fallback before wider testing.

## Security Notes

- Do not embed provider keys in the app bundle, Keychain, Info.plist, or remote client config.
- Authenticate app requests with tenant/user session tokens, not LLM provider keys.
- Sign image upload URLs and set short expiration.
- Redact inventory and image metadata from logs unless explicitly needed for support.
- Treat prompt templates as backend code, versioned and deployable without App Store releases.

## Cloudflare References

- Workers limits: https://developers.cloudflare.com/workers/platform/limits/
- Workers best practices: https://developers.cloudflare.com/workers/best-practices/workers-best-practices/
- R2 upload methods: https://developers.cloudflare.com/r2/objects/upload-objects/
- Queues configuration: https://developers.cloudflare.com/queues/configuration/configure-queues/
- Workflows limits: https://developers.cloudflare.com/workflows/reference/limits/
- AI Gateway changelog and capabilities: https://developers.cloudflare.com/changelog/product/ai-gateway/
