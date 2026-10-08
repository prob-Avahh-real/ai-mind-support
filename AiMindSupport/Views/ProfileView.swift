import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showSettings = false
    
    var body: some View {
        NavigationView {
            List {
                // User Info Section
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("用户 ID")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(authManager.currentUser?.uid ?? "Unknown")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        if authManager.currentUser?.isAnonymous == true {
                            Text("匿名")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }
                }
                
                // Account Actions
                Section {
                    Button(action: {
                        showSettings = true
                    }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("设置")
                        }
                    }
                    
                    if authManager.currentUser?.isAnonymous == true {
                        Button(action: {
                            // Show email link dialog
                        }) {
                            HStack {
                                Image(systemName: "envelope")
                                Text("关联邮箱账号")
                            }
                        }
                    }
                }
                
                // Privacy & Security
                Section(header: Text("隐私与安全")) {
                    NavigationLink(destination: PrivacyPolicyView()) {
                        HStack {
                            Image(systemName: "shield")
                            Text("隐私政策")
                        }
                    }
                    
                    NavigationLink(destination: DataManagementView()) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("数据管理")
                        }
                    }
                    
                    NavigationLink(destination: EmergencyContactsView()) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                            Text("紧急联系人")
                        }
                    }
                }
                
                // About
                Section(header: Text("关于")) {
                    NavigationLink(destination: AboutView()) {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("关于应用")
                        }
                    }
                    
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Sign Out
                Section {
                    Button(action: {
                        authManager.signOut()
                    }) {
                        HStack {
                            Spacer()
                            Text("退出登录")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("外观")) {
                    Toggle("深色模式", isOn: $darkMode)
                }
                
                Section(header: Text("通知")) {
                    Toggle("启用通知", isOn: $notificationsEnabled)
                }
                
                Section(header: Text("语言")) {
                    HStack {
                        Text("语言")
                        Spacer()
                        Text("简体中文")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("隐私政策")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("最后更新：2026年5月")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("""
我们非常重视您的隐私。本隐私政策说明了我们如何收集、使用和保护您的个人信息。

**信息收集**
- 对话内容：为了提供心理健康支持服务，我们会收集您的对话内容
- 使用数据：我们会收集应用使用情况以改进服务
- 设备信息：我们会收集基本的设备信息以确保服务正常运行

**信息使用**
- 提供和改进我们的服务
- 确保安全和防止欺诈
- 遵守法律义务

**数据保护**
- 所有数据都经过加密传输和存储
- 我们遵循HIPAA合规要求
- 我们不会出售您的个人信息

**您的权利**
- 访问您的数据
- 删除您的数据
- 导出您的数据
- 修改您的设置

**危机干预**
在危机情况下，我们可能会提供紧急资源信息，但不会自动联系紧急服务，除非您明确要求。
""")
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle("隐私政策")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Data Management View

struct DataManagementView: View {
    var body: some View {
        List {
            Section {
                Button(action: {
                    // Export data functionality
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("导出我的数据")
                    }
                }
                
                Button(action: {
                    // Delete all data functionality
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("删除所有数据")
                            .foregroundColor(.red)
                    }
                }
            } header: {
                Text("数据操作")
            } footer: {
                Text("删除所有数据是不可逆的操作。请谨慎操作。")
            }
        }
        .navigationTitle("数据管理")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Emergency Contacts View

struct EmergencyContactsView: View {
    @State private var contacts: [EmergencyContact] = []
    @State private var showAddContact = false
    
    var body: some View {
        List {
            ForEach(contacts) { contact in
                EmergencyContactRow(contact: contact)
            }
            .onDelete(perform: deleteContacts)
            
            Button(action: {
                showAddContact = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("添加紧急联系人")
                }
            }
        }
        .navigationTitle("紧急联系人")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddContact) {
            AddEmergencyContactView { newContact in
                contacts.append(newContact)
            }
        }
    }
    
    private func deleteContacts(at offsets: IndexSet) {
        contacts.remove(atOffsets: offsets)
    }
}

struct EmergencyContact: Identifiable, Codable {
    let id = UUID()
    let name: String
    let relationship: String
    let phoneNumber: String
}

struct EmergencyContactRow: View {
    let contact: EmergencyContact
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(contact.name)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(contact.relationship)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(contact.phoneNumber)
                .font(.caption)
                .foregroundColor(.blue)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let url = URL(string: "tel:\(contact.phoneNumber)") {
                UIApplication.shared.open(url)
            }
        }
    }
}

struct AddEmergencyContactView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var relationship = ""
    @State private var phoneNumber = ""
    
    let onSave: (EmergencyContact) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("姓名", text: $name)
                    TextField("关系", text: $relationship)
                    TextField("电话号码", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section {
                    Button(action: saveContact) {
                        Text("保存")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(name.isEmpty || phoneNumber.isEmpty)
                }
            }
            .navigationTitle("添加联系人")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveContact() {
        let contact = EmergencyContact(
            name: name,
            relationship: relationship,
            phoneNumber: phoneNumber
        )
        onSave(contact)
        dismiss()
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI Mind Support")
                            .font(.headline)
                        
                        Text("心理健康支持AI")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "heart.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
            }
            
            Section {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("构建")
                    Spacer()
                    Text("2026.05.26")
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Button(action: {
                    if let url = URL(string: "https://github.com/yourusername/ai-mind-support") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "link")
                        Text("GitHub 仓库")
                    }
                }
                
                Button(action: {
                    if let url = URL(string: "mailto:support@aimindsupport.com") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "envelope")
                        Text("联系支持")
                    }
                }
            }
            
            Section {
                Text("""
AI Mind Support 是一个心理健康支持应用，提供安全的对话环境和危机干预资源。

本应用不替代专业的心理健康服务。如果您或您认识的人正在经历心理健康危机，请立即寻求专业帮助。

**免责声明**
本应用提供的信息和建议仅供参考，不构成医疗建议。对于任何健康相关问题，请咨询合格的专业人士。
""")
                    .font(.caption)
            }
        }
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthenticationManager())
    }
}