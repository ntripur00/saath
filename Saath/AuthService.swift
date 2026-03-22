import Foundation
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices
import CryptoKit
import Combine

// MARK: - Auth User model (decoupled from Firebase)

struct AuthUser {
    let uid:         String
    let displayName: String
    let email:       String
    let photoURL:    URL?

    var initials: String {
        let parts = displayName.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(displayName.prefix(2)).uppercased()
    }

    init(from user: FirebaseAuth.User) {
        self.uid         = user.uid
        self.displayName = user.displayName ?? user.email ?? "User"
        self.email       = user.email ?? ""
        self.photoURL    = user.photoURL
    }
}

// MARK: - AuthService

class AuthService: ObservableObject {

    static let shared = AuthService()

    @Published var currentUser:    AuthUser?   = nil
    @Published var isLoading:      Bool        = false
    @Published var errorMessage:   String?     = nil

    var isSignedIn: Bool { currentUser != nil }

    private var stateListener: AuthStateDidChangeListenerHandle?

    // Used for Apple Sign-In nonce
    private var currentNonce: String?

    private init() {
        // Listen for Firebase auth state changes
        stateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            self.currentUser = user.map { AuthUser(from: $0) }
        }
    }

    deinit {
        if let handle = stateListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async {
        isLoading    = true
        errorMessage = nil

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Firebase configuration error."
            isLoading    = false
            return
        }

        // Get the root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first?.rootViewController else {
            errorMessage = "Cannot present sign-in screen."
            isLoading    = false
            return
        }

        do {
            let config   = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            let result   = try await GIDSignIn.sharedInstance.signIn(withPresenting: root)
            let user     = result.user
            guard let idToken = user.idToken?.tokenString else {
                throw NSError(domain: "AuthService", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Missing ID token"])
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            try await Auth.auth().signIn(with: credential)

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Apple Sign-In

    /// Call this to get the ASAuthorizationAppleIDRequest to pass to the button/controller.
    func appleSignInRequest() -> ASAuthorizationAppleIDRequest {
        let nonce   = randomNonceString()
        currentNonce = nonce
        let provider = ASAuthorizationAppleIDProvider()
        let request  = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        return request
    }

    /// Call this after the Apple authorization completes successfully.
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        isLoading    = true
        errorMessage = nil

        switch result {
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8),
                  let nonce = currentNonce
            else {
                errorMessage = "Apple Sign-In failed: invalid credential"
                isLoading    = false
                return
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken:     idTokenString,
                rawNonce:        nonce,
                fullName:        appleIDCredential.fullName
            )

            do {
                try await Auth.auth().signIn(with: credential)
            } catch {
                errorMessage = error.localizedDescription
            }

        case .failure(let error):
            // User cancelled is not an error worth showing
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Apple Nonce Helpers

    private func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result    = ""
        var remaining = length
        while remaining > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("SecRandomCopyBytes failed: \(errorCode)")
                }
                return random
            }
            randoms.forEach { random in
                if remaining == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let data   = Data(input.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
