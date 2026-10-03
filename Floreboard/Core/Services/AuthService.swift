//
//  AuthService.swift
//  Floreboard
//
//  JWT-based authentication service aligned with floreboard-web backend.
//

import Combine
import Foundation

// MARK: - Auth Models

struct AuthTokens: Codable {
  let accessToken: String
  let refreshToken: String?
  let expiresIn: Int?

  init(accessToken: String, refreshToken: String? = nil, expiresIn: Int? = 3600 * 24 * 30) {
    self.accessToken = accessToken
    self.refreshToken = refreshToken
    self.expiresIn = expiresIn
  }
}

struct AuthUser: Codable {
  let id: String
  let email: String
  let createdAt: String?

  enum CodingKeys: String, CodingKey {
    case id, email
    case createdAt = "created_at"
  }
}

struct AuthResponse: Codable {
  let success: Bool?
  let token: String?
  let user: AuthUser?
  let tenant: Tenant?
  let error: String?
}

struct MeResponse: Codable {
  let success: Bool
  let user: AuthUser?
  let tenant: Tenant?
  let error: String?
}

struct SigninRequest: Codable {
  let email: String
  let password: String
}

struct SignupRequest: Codable {
  let email: String
  let password: String
  let shopName: String
}

// MARK: - Auth Service

@MainActor
class AuthService: ObservableObject {
  @Published var isAuthenticated: Bool = false
  @Published var isNewlyRegistered: Bool = false
  @Published var currentUser: AuthUser?
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

  var authBaseURL: String {
    if let value = Bundle.main.object(forInfoDictionaryKey: "FLOREBOARD_AI_PROXY_BASE_URL") as? String,
      !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      var cleanValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
      if !cleanValue.hasPrefix("http") {
        cleanValue = "https://" + cleanValue
      }
      if cleanValue.contains("workers.dev") {
        return "https://api.floreboard.com"
      }
      return cleanValue
    }

    if let value = UserDefaults.standard.string(forKey: "ai_proxy_base_url"),
      !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      var cleanValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
      if !cleanValue.hasPrefix("http") {
        cleanValue = "https://" + cleanValue
      }
      if cleanValue.contains("workers.dev") {
        UserDefaults.standard.set("https://api.floreboard.com", forKey: "ai_proxy_base_url")
        return "https://api.floreboard.com"
      }
      return cleanValue
    }

    return "https://api.floreboard.com"
  }

  private init() {
    // Restore session from Keychain & UserDefaults
    if KeychainManager.shared.load(forKey: "access_token") != nil {
      if let tenantData = UserDefaults.standard.data(forKey: "current_tenant"),
        let tenant = try? JSONDecoder().decode(Tenant.self, from: tenantData) {
        self.currentTenant = tenant
      }
      if let userData = UserDefaults.standard.data(forKey: "current_user"),
        let user = try? JSONDecoder().decode(AuthUser.self, from: userData) {
        self.currentUser = user
      }
      self.isAuthenticated = true

      if let exp = UserDefaults.standard.object(forKey: "token_expires_at") as? Date {
        self.tokenExpiresAt = exp
      }

      // Silent refresh session info from server
      Task {
        _ = await self.fetchMe()
      }
    }
  }

  func login(email: String, password: String) async -> Bool {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    // Test account backdoor
    if (email == "test" || email == "test@floreboard.com") && password == "123456" {
      let mockTokens = AuthTokens(accessToken: "mock_access_token", refreshToken: "mock_refresh_token", expiresIn: 3600)
      let mockUser = AuthUser(id: "user_test", email: "test@floreboard.com", createdAt: nil)
      let mockTenant = Tenant(
        id: "tenant_test", name: "Test Store", ownerId: "user_test",
        credits: 100, tier: "pro", subscriptionExpiresAt: nil)
      saveSession(token: mockTokens.accessToken, user: mockUser, tenant: mockTenant)
      return true
    }

    do {
      guard let url = URL(string: "\(authBaseURL)/api/v1/auth/signin") else {
        self.errorMessage = "Invalid API URL configuration."
        return false
      }
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")

      let body = SigninRequest(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
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
      guard let token = authResponse.token else {
        throw AuthError.serverError(authResponse.error ?? "Failed to acquire token")
      }

      saveSession(token: token, user: authResponse.user, tenant: authResponse.tenant)
      return true
    } catch let error as AuthError {
      errorMessage = error.localizedDescription
      return false
    } catch {
      errorMessage = error.localizedDescription
      return false
    }
  }

  /// Backward-compatible overload
  func login(storeName: String, password: String) async -> Bool {
    await login(email: storeName, password: password)
  }

  func register(email: String, password: String, shopName: String) async -> Bool {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    do {
      guard let url = URL(string: "\(authBaseURL)/api/v1/auth/signup") else {
        self.errorMessage = "Invalid API URL configuration."
        return false
      }
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")

      let body = SignupRequest(
        email: email.trimmingCharacters(in: .whitespacesAndNewlines),
        password: password,
        shopName: shopName.trimmingCharacters(in: .whitespacesAndNewlines)
      )
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
      guard let token = authResponse.token else {
        throw AuthError.serverError(authResponse.error ?? "Registration failed")
      }

      DispatchQueue.main.async {
        self.isNewlyRegistered = true
      }
      saveSession(token: token, user: authResponse.user, tenant: authResponse.tenant)
      return true
    } catch let error as AuthError {
      errorMessage = error.localizedDescription
      return false
    } catch {
      errorMessage = error.localizedDescription
      return false
    }
  }

  func fetchMe() async -> Bool {
    guard let token = accessToken, !token.isEmpty else { return false }
    guard let url = URL(string: "\(authBaseURL)/api/v1/auth/me") else { return false }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
        if (response as? HTTPURLResponse)?.statusCode == 401 {
          logout()
        }
        return false
      }

      let meResp = try JSONDecoder().decode(MeResponse.self, from: data)
      if let user = meResp.user {
        self.currentUser = user
        if let data = try? JSONEncoder().encode(user) {
          UserDefaults.standard.set(data, forKey: "current_user")
        }
      }
      if let tenant = meResp.tenant {
        self.currentTenant = tenant
        if let data = try? JSONEncoder().encode(tenant) {
          UserDefaults.standard.set(data, forKey: "current_tenant")
        }
      }
      return true
    } catch {
      return false
    }
  }

  func refreshTokenIfNeeded() async throws {
    // Current backend tokens are long-lived (30 days), silence unless explicitly expired
    _ = await fetchMe()
  }

  func logout() {
    KeychainManager.shared.delete(forKey: "access_token")
    KeychainManager.shared.delete(forKey: "refresh_token")
    UserDefaults.standard.removeObject(forKey: "current_tenant")
    UserDefaults.standard.removeObject(forKey: "current_user")
    UserDefaults.standard.removeObject(forKey: "token_expires_at")
    currentUser = nil
    currentTenant = nil
    isAuthenticated = false
    errorMessage = nil
  }

  private func saveSession(token: String, user: AuthUser?, tenant: Tenant?) {
    _ = KeychainManager.shared.save(token, forKey: "access_token")
    self.currentUser = user
    self.currentTenant = tenant
    self.isAuthenticated = true

    if let user, let data = try? JSONEncoder().encode(user) {
      UserDefaults.standard.set(data, forKey: "current_user")
    }
    if let tenant, let data = try? JSONEncoder().encode(tenant) {
      UserDefaults.standard.set(data, forKey: "current_tenant")
    }
    // 30 days expiration
    let exp = Date().addingTimeInterval(30 * 24 * 3600)
    tokenExpiresAt = exp
    UserDefaults.standard.set(exp, forKey: "token_expires_at")
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
