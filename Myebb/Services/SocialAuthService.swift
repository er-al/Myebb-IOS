//
//  SocialAuthService.swift
//  Myebb
//
//  Created by ChatGPT on 12/7/25.
//

import AuthenticationServices
import Foundation
import UIKit
import GoogleSignIn

enum SocialProvider: String {
    case google
}

enum SocialAuthError: LocalizedError {
    case missingConfig(String)
    case invalidRedirect
    case tokenNotFound
    case cancelled

    var errorDescription: String? {
        switch self {
        case .missingConfig(let name):
            return "\(name) is not configured"
        case .invalidRedirect:
            return "Unable to complete sign-in flow"
        case .tokenNotFound:
            return "Login token was not returned"
        case .cancelled:
            return "Sign-in was cancelled"
        }
    }
}

final class SocialAuthService: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = SocialAuthService()
    private override init() {}

    private let sessionAnchor: ASPresentationAnchor = {
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = scene.windows.first(where: { $0.isKeyWindow })
        else {
            return ASPresentationAnchor()
        }
        return window
    }()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        sessionAnchor
    }

    func signInWithGoogle() async throws -> String {
        guard !AppConfig.googleClientID.isEmpty else {
            throw SocialAuthError.missingConfig("Google Client ID")
        }
        guard let presentingVC = Self.topViewController() else {
            throw SocialAuthError.invalidRedirect
        }

        // Configure and use the async GoogleSignIn API to avoid manual OAuth URL construction issues.
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: AppConfig.googleClientID)
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC)
        guard let idToken = result.user.idToken?.tokenString else {
            throw SocialAuthError.tokenNotFound
        }
        // Debug: log the ID token audience for backend verification.
        print("[GoogleSignIn] Successfully retrieved ID token")
        return idToken
    }


    private func startSession(url: URL, callbackScheme: String, tokenKey: String, state: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { callbackURL, error in
                if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin {
                    continuation.resume(throwing: SocialAuthError.cancelled)
                    return
                }

                guard let callbackURL else {
                    continuation.resume(throwing: SocialAuthError.invalidRedirect)
                    return
                }

                let fragment = callbackURL.fragment ?? callbackURL.query ?? ""
                let params = Self.parseParams(fragment)

                if let returnedState = params["state"], returnedState != state {
                    continuation.resume(throwing: SocialAuthError.invalidRedirect)
                    return
                }

                if let errorDescription = params["error_description"] ?? params["error"] {
                    continuation.resume(throwing: NSError(domain: "SocialAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: errorDescription]))
                    return
                }

                guard let token = params[tokenKey] else {
                    continuation.resume(throwing: SocialAuthError.tokenNotFound)
                    return
                }

                continuation.resume(returning: token)
            }

            session.prefersEphemeralWebBrowserSession = true
            session.presentationContextProvider = self
            session.start()
        }
    }

    private static func parseParams(_ fragment: String) -> [String: String] {
        fragment
            .split(separator: "&")
            .reduce(into: [String: String]()) { result, pair in
                let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
                guard let key = parts.first else { return }
                let value = parts.count > 1 ? parts[1].removingPercentEncoding ?? parts[1] : ""
                result[key] = value
            }
    }
}

private extension SocialAuthService {
    static func topViewController(base: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}

