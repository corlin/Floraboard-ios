//
//  AuthService.swift
//  Floreboard
//
//  JWT-based authentication service.
//

import Combine
import Foundation

// MARK: - Auth Models

struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int  // seconds
}

struct AuthResponse: Codable {
    let tokens: AuthTokens
    let tenant: Tenant
}

struct LoginRequest: Codable {
    let storeName: String
    let password: String
}

// MARK: - Auth Service

@MainActor
class AuthService: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentTenant: Tenant?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    static let shared = AuthService()

    private var tokenExpiresAt: Date?

    /// The current access token for API authorization
    var accessToken: String? {
        KeychainManager.shared.load(forKey: "access_token")
    }

    private var refreshToken: String? {
        KeychainManager.shared.load(forKey: "refresh_token")
    }

    private var authBaseURL: String {
        // Use the same base URL as the AI proxy
        if let value = Bundle.main.object(forInfoDictionaryKey: "FLOREBOARD_AI_PROXY_BASE_URL")
            as? String,
            !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let value = UserDefaults.standard.string(forKey: "ai_proxy_base_url"),
            !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return "https://floreboard-ai-proxy.cybercorlin.workers.dev"
    }

    private init() {
        // Restore session from Keychain
        if let _ = KeychainManager.shared.load(forKey: "access_token"),
            let tenantData = UserDefaults.standard.data(forKey: "current_tenant"),
            let tenant = try? JSONDecoder().decode(Tenant.self, from: tenantData)
        {
            self.currentTenant = tenant
            self.isAuthenticated = true
            // Restore expiration
            if let exp = UserDefaults.standard.object(forKey: "token_expires_at") as? Date {
                self.tokenExpiresAt = exp
            }
        }
    }

    func login(storeName: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Test account backdoor
        if storeName == "test" && password == "123456" {
            let mockTokens = AuthTokens(accessToken: "mock_access_token", refreshToken: "mock_refresh_token", expiresIn: 3600)
            let mockTenant = Tenant(id: "tenant_test", name: "Test Store")
            saveSession(tokens: mockTokens, tenant: mockTenant)
            return true
        }

        do {
            let url = URL(string: "\(authBaseURL)/v1/auth/login")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            let body = LoginRequest(storeName: storeName, password: password)
            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                if let errResp = try? JSONDecoder().decode(AIProxyErrorResponse.self, from: data) {
                    throw AuthError.serverError(errResp.message)
                }
                throw AuthError.httpError(httpResponse.statusCode)
            }

            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            saveSession(tokens: authResponse.tokens, tenant: authResponse.tenant)
            return true
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func refreshTokenIfNeeded() async throws {
        guard let expiresAt = tokenExpiresAt,
            expiresAt.timeIntervalSinceNow < 60,  // Refresh if < 60s remaining
            let refreshTkn = refreshToken
        else {
            return
        }

        let url = URL(string: "\(authBaseURL)/v1/auth/refresh")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["refreshToken": refreshTkn])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
            (200..<300).contains(httpResponse.statusCode)
        else {
            // Refresh failed — force logout
            logout()
            throw AuthError.sessionExpired
        }

        let tokens = try JSONDecoder().decode(AuthTokens.self, from: data)
        storeTokens(tokens)
    }

    func logout() {
        KeychainManager.shared.delete(forKey: "access_token")
        KeychainManager.shared.delete(forKey: "refresh_token")
        UserDefaults.standard.removeObject(forKey: "current_tenant")
        UserDefaults.standard.removeObject(forKey: "token_expires_at")
        currentTenant = nil
        isAuthenticated = false
        errorMessage = nil
    }

    private func saveSession(tokens: AuthTokens, tenant: Tenant) {
        storeTokens(tokens)
        self.currentTenant = tenant
        self.isAuthenticated = true
        if let data = try? JSONEncoder().encode(tenant) {
            UserDefaults.standard.set(data, forKey: "current_tenant")
        }
    }

    private func storeTokens(_ tokens: AuthTokens) {
        let _ = KeychainManager.shared.save(tokens.accessToken, forKey: "access_token")
        let _ = KeychainManager.shared.save(tokens.refreshToken, forKey: "refresh_token")
        tokenExpiresAt = Date().addingTimeInterval(TimeInterval(tokens.expiresIn))
        UserDefaults.standard.set(tokenExpiresAt, forKey: "token_expires_at")
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case serverError(String)
    case sessionExpired

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return Tx.t("error.api.invalidResponse")
        case .httpError(let code): return Tx.t("error.apiError", ["code": "\(code)"])
        case .serverError(let msg): return msg
        case .sessionExpired: return Tx.t("error.authentication")
        }
    }
}
