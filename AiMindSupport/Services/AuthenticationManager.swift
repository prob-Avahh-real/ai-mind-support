import Foundation
import Combine
import FirebaseAuth

// MARK: - Authentication Manager

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let auth = Auth.auth()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAuthListener()
    }
    
    // MARK: - Setup
    
    private func setupAuthListener() {
        auth.addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                self?.currentUser = user
            }
        }
    }
    
    // MARK: - Public Methods
    
    func signInAnonymously() {
        isLoading = true
        errorMessage = nil
        
        auth.signInAnonymously { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.isAuthenticated = true
                    self?.currentUser = result?.user
                }
            }
        }
    }
    
    func signOut() {
        do {
            try auth.signOut()
            DispatchQueue.main.async {
                self.isAuthenticated = false
                self.currentUser = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func linkAccount(email: String, password: String) {
        guard let currentUser = currentUser else {
            errorMessage = "No current user to link"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let credential = EmailPasswordAuthProvider.credential(withEmail: email, password: password)
        
        currentUser.link(with: credential) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    // Account linked successfully
                    self?.currentUser = result?.user
                }
            }
        }
    }
}

// MARK: - User Model

struct User {
    let uid: String
    let email: String?
    let isAnonymous: Bool
    
    init(from firebaseUser: FirebaseAuth.User) {
        self.uid = firebaseUser.uid
        self.email = firebaseUser.email
        self.isAnonymous = firebaseUser.isAnonymous
    }
}