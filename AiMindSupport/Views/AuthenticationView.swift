import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showEmailLink = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                // Logo and Title
                VStack(spacing: 10) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("AI Mind Support")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("心理健康支持")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Authentication Options
                VStack(spacing: 15) {
                    // Anonymous Sign In
                    Button(action: {
                        authManager.signInAnonymously()
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle")
                            Text("匿名开始")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(authManager.isLoading)
                    
                    // Link Account
                    Button(action: {
                        showEmailLink = true
                    }) {
                        HStack {
                            Image(systemName: "envelope")
                            Text("关联邮箱账号")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Privacy Notice
                VStack(spacing: 8) {
                    Text("隐私说明")
                        .font(.headline)
                    
                    Text("您的对话内容会被加密存储，我们承诺保护您的隐私。紧急情况下，我们会提供危机干预资源。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
            .alert("错误", isPresented: .constant(authManager.errorMessage != nil)) {
                Button("确定") {
                    authManager.errorMessage = nil
                }
            } message: {
                if let error = authManager.errorMessage {
                    Text(error)
                }
            }
            .sheet(isPresented: $showEmailLink) {
                EmailLinkView()
            }
        }
    }
}

struct EmailLinkView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("邮箱", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("密码", text: $password)
                        .textContentType(.password)
                }
                
                Section {
                    Button(action: {
                        authManager.linkAccount(email: email, password: password)
                        if authManager.errorMessage == nil {
                            dismiss()
                        }
                    }) {
                        Text("关联账号")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.medium)
                    }
                    .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
                }
            }
            .navigationTitle("关联邮箱")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("错误", isPresented: .constant(authManager.errorMessage != nil)) {
                Button("确定") {
                    authManager.errorMessage = nil
                }
            } message: {
                if let error = authManager.errorMessage {
                    Text(error)
                }
            }
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
            .environmentObject(AuthenticationManager())
    }
}