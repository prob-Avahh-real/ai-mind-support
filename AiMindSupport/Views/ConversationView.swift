import SwiftUI

struct ConversationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var safetyEngine: SafetyEngine
    @StateObject private var conversationService = ConversationService()
    
    @State private var messageText = ""
    @State private var currentConversation: Conversation?
    
    var body: some View {
        NavigationView {
            VStack {
                if let conversation = currentConversation {
                    // Messages List
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(conversation.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: conversation.messages.count) { _ in
                            if let lastMessage = conversation.messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // Input Area
                    VStack(spacing: 0) {
                        Divider()
                        
                        HStack(spacing: 12) {
                            TextField("说点什么...", text: $messageText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disabled(conversationService.isLoading)
                            
                            Button(action: sendMessage) {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(messageText.isEmpty ? Color.gray : Color.blue)
                                    .clipShape(Circle())
                            }
                            .disabled(messageText.isEmpty || conversationService.isLoading)
                        }
                        .padding()
                    }
                } else {
                    // Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "message.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("开始新的对话")
                            .font(.headline)
                        
                        Text("点击下方按钮开始")
                            .foregroundColor(.secondary)
                        
                        Button(action: startNewConversation) {
                            Text("开始对话")
                                .fontWeight(.medium)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .navigationTitle("对话")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if currentConversation != nil {
                        Button("结束") {
                            endConversation()
                        }
                    }
                }
            }
            .alert("错误", isPresented: .constant(conversationService.errorMessage != nil)) {
                Button("确定") {
                    conversationService.errorMessage = nil
                }
            } message: {
                if let error = conversationService.errorMessage {
                    Text(error)
                }
            }
        }
        .onAppear {
            if let userId = authManager.currentUser?.uid {
                conversationService.loadConversations(userId: userId)
            }
        }
    }
    
    private func startNewConversation() {
        guard let userId = authManager.currentUser?.uid else { return }
        
        let newConversation = conversationService.createConversation(userId: userId)
        currentConversation = newConversation
        conversationService.loadMessages(conversationId: newConversation.id)
    }
    
    private func sendMessage() {
        guard let userId = authManager.currentUser?.uid,
              let conversation = currentConversation,
              !messageText.isEmpty else { return }
        
        // Process through safety engine first
        let preLlmResult = safetyEngine.processUserMessage(messageText)
        
        if preLlmResult.shouldBlockLlm {
            // Crisis detected - show fixed response
            let crisisMessage = ConversationContext.Message(
                role: "assistant",
                text: preLlmResult.fixedResponse ?? "",
                timestamp: Date(),
                crisisLevel: preLlmResult.crisisLevel
            )
            
            // Save user message with crisis level
            let userMessage = UserMessage(
                userId: userId,
                conversationId: conversation.id,
                text: messageText,
                crisisLevel: preLlmResult.crisisLevel
            )
            
            // Save both messages
            conversationService.sendMessage(userMessage) { _ in
                // Save crisis response
                DispatchQueue.main.async {
                    if let index = self.conversationService.conversations.firstIndex(where: { $0.id == conversation.id }) {
                        self.conversationService.conversations[index].messages.append(userMessage.toContextMessage())
                        self.conversationService.conversations[index].messages.append(crisisMessage)
                    }
                }
            }
            
            messageText = ""
            return
        }
        
        // Normal message processing
        let userMessage = UserMessage(
            userId: userId,
            conversationId: conversation.id,
            text: preLlmResult.sanitizedText
        )
        
        conversationService.sendMessage(userMessage) { response in
            DispatchQueue.main.async {
                if let response = response {
                    // Process AI response through safety engine
                    let postLlmResult = self.safetyEngine.processLlmOutput(response)
                    
                    let aiMessage = ConversationContext.Message(
                        role: "assistant",
                        text: postLlmResult.finalText,
                        timestamp: Date()
                    )
                    
                    if let index = self.conversationService.conversations.firstIndex(where: { $0.id == conversation.id }) {
                        self.conversationService.conversations[index].messages.append(userMessage.toContextMessage())
                        self.conversationService.conversations[index].messages.append(aiMessage)
                    }
                }
            }
        }
        
        messageText = ""
    }
    
    private func endConversation() {
        currentConversation = nil
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ConversationContext.Message
    
    var body: some View {
        HStack {
            if message.role == "user" {
                Spacer()
                messageContent
                    .background(Color.blue)
                    .foregroundColor(.white)
            } else {
                messageContent
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                Spacer()
            }
        }
    }
    
    private var messageContent: some View {
        VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
            Text(message.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .cornerRadius(18)
            
            if let crisisLevel = message.crisisLevel, crisisLevel != .normal {
               危机Indicator(level: crisisLevel)
            }
        }
    }
}

struct 危机Indicator: View {
    let level: CrisisLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level == .explicit ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                .font(.caption)
            Text(level == .explicit ? "高危" : "关注")
                .font(.caption)
        }
        .foregroundColor(level == .explicit ? .red : .orange)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(level == .explicit ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
        .cornerRadius(4)
    }
}

// MARK: - Extensions

extension UserMessage {
    func toContextMessage() -> ConversationContext.Message {
        return ConversationContext.Message(
            role: "user",
            text: text,
            timestamp: timestamp,
            crisisLevel: crisisLevel
        )
    }
}

struct ConversationView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationView()
            .environmentObject(AuthenticationManager())
            .environmentObject(SafetyEngine())
    }
}