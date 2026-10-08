import Foundation
import Combine
import FirebaseFirestore

// MARK: - Conversation Service

class ConversationService: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var currentConversation: Conversation?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    func createConversation(userId: String) -> Conversation {
        let conversation = Conversation(
            id: UUID().uuidString,
            userId: userId,
            createdAt: Date(),
            updatedAt: Date(),
            metadata: ConversationMetadata()
        )
        
        // Save to Firestore
        do {
            try db.collection("conversations").document(conversation.id).setData(from: conversation)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        return conversation
    }
    
    func loadConversations(userId: String) {
        isLoading = true
        errorMessage = nil
        
        db.collection("conversations")
            .whereField("userId", isEqualTo: userId)
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        self?.conversations = []
                        return
                    }
                    
                    self?.conversations = documents.compactMap { document in
                        try? document.data(as: Conversation.self)
                    }
                }
            }
    }
    
    func sendMessage(_ message: UserMessage, completion: @escaping (String?) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // Save user message to Firestore
        do {
            try db.collection("conversations")
                .document(message.conversationId)
                .collection("messages")
                .document(message.id)
                .setData(from: message)
            
            // Update conversation timestamp
            db.collection("conversations")
                .document(message.conversationId)
                .updateData(["updatedAt": Date()])
            
            // Here you would typically call your Cloud Function to get AI response
            // For now, we'll simulate a response
            simulateAIResponse(for: message, completion: completion)
            
        } catch {
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.errorMessage = error.localizedDescription
                completion(nil)
            }
        }
    }
    
    func loadMessages(conversationId: String) {
        isLoading = true
        errorMessage = nil
        
        db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp", ascending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        return
                    }
                    
                    let messages = documents.compactMap { document -> ConversationContext.Message? in
                        try? document.data(as: ConversationContext.Message.self)
                    }
                    
                    // Update current conversation with messages
                    if let index = self?.conversations.firstIndex(where: { $0.id == conversationId }) {
                        self?.conversations[index].messages = messages
                    }
                }
            }
    }
    
    // MARK: - Private Methods
    
    private func simulateAIResponse(for message: UserMessage, completion: @escaping (String?) -> Void) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            
            // Simple echo response for now
            let response = "我听到了你说的话。你能多说说吗？"
            
            // Save AI response to Firestore
            let aiMessage = ConversationContext.Message(
                role: "assistant",
                text: response,
                timestamp: Date()
            )
            
            do {
                try self?.db.collection("conversations")
                    .document(message.conversationId)
                    .collection("messages")
                    .document()
                    .setData(from: aiMessage)
                
                completion(response)
            } catch {
                self?.errorMessage = error.localizedDescription
                completion(nil)
            }
        }
    }
}

// MARK: - Conversation Model

struct Conversation: Identifiable, Codable {
    let id: String
    let userId: String
    let createdAt: Date
    var updatedAt: Date
    var messages: [ConversationContext.Message]
    var metadata: ConversationMetadata
    
    init(id: String = UUID().uuidString, userId: String, createdAt: Date = Date(), updatedAt: Date = Date(), messages: [ConversationContext.Message] = [], metadata: ConversationMetadata = ConversationMetadata()) {
        self.id = id
        self.userId = userId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = messages
        self.metadata = metadata
    }
}