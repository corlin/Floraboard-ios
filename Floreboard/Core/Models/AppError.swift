import Foundation

enum AppError: LocalizedError {
  case network(String)
  case server(String)
  case authentication
  case quotaExceeded
  case unknown(String)

  init(from error: Error) {
    if let aiError = error as? AIError {
      switch aiError {
      case .missingApiKey:
        self = .authentication
      case .invalidURL:
        self = .unknown(Tx.t("error.invalidURL"))
      case .apiError(let code):
        if code == 401 || code == 403 {
          self = .authentication
        } else if code >= 500 {
          self = .server(Tx.t("error.serverUnavailable"))
        } else {
          self = .unknown(Tx.t("error.apiError", ["code": "\(code)"]))
        }
      case .imageEncodingFailed:
        self = .unknown(Tx.t("error.imageEncodingFailed"))
      }
    } else if let proxyError = error as? AIProxyError {
      switch proxyError {
      case .invalidURL:
        self = .unknown(Tx.t("error.invalidURL"))
      case .invalidResponse:
        self = .server(Tx.t("error.api.invalidResponse"))
      case .httpStatus(let code):
        if code == 401 || code == 403 {
          self = .authentication
        } else if code >= 500 {
          self = .server(Tx.t("error.serverUnavailable"))
        } else {
          self = .unknown(Tx.t("error.apiError", ["code": "\(code)"]))
        }
      case .rejected(let resp):
        // If the backend returned a specific error message, we display it directly
        self = .server(resp.message)
      case .insufficientQuota:
        self = .quotaExceeded
      }
    } else {
      let nsError = error as NSError
      if nsError.domain == NSURLErrorDomain {
        self = .network(Tx.t("error.network"))
      } else {
        self = .unknown(error.localizedDescription)
      }
    }
  }

  var errorDescription: String? {
    switch self {
    case .network(let msg): return msg
    case .server(let msg): return msg
    case .authentication: return Tx.t("error.authentication")
    case .quotaExceeded: return Tx.t("error.api.insufficientQuota")
    case .unknown(let msg): return msg
    }
  }
}
