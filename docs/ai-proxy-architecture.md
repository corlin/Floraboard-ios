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
The client sends a compressed base64 image or uploads it first and passes an `imageUploadId`.

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
3. Introduce an `AIProxyClient` that calls Floreboard endpoints and returns normalized response models.
4. Move prompt construction, provider headers, model IDs, and provider response parsing out of iOS.
5. Keep the current direct-provider path only as an internal debug fallback, hidden from production UI.
6. Add backend quota, request logs, and provider fallback before wider testing.

## Security Notes

- Do not embed provider keys in the app bundle, Keychain, Info.plist, or remote client config.
- Authenticate app requests with tenant/user session tokens, not LLM provider keys.
- Sign image upload URLs and set short expiration.
- Redact inventory and image metadata from logs unless explicitly needed for support.
- Treat prompt templates as backend code, versioned and deployable without App Store releases.
