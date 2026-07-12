import Foundation

// MARK: - Core Types

enum CrisisLevel: Int, Codable {
    case normal = 1
    case implied = 2
    case explicit = 3
}

enum Language: String, Codable {
    case chinese = "zh"
    case english = "en"
}

// MARK: - User Message

struct UserMessage: Identifiable, Codable {
    let id: String
    let userId: String
    let conversationId: String
    let text: String
    let timestamp: Date
    var crisisLevel: CrisisLevel?
    
    init(id: String = UUID().uuidString, userId: String, conversationId: String, text: String, timestamp: Date = Date(), crisisLevel: CrisisLevel? = nil) {
        self.id = id
        self.userId = userId
        self.conversationId = conversationId
        self.text = text
        self.timestamp = timestamp
        self.crisisLevel = crisisLevel
    }
}

// MARK: - Conversation Context

struct ConversationContext: Codable {
    let conversationId: String
    let userId: String
    var messages: [Message]
    
    struct Message: Identifiable, Codable {
        let id: String
        let role: String // "user" or "assistant"
        let text: String
        let timestamp: Date
        var crisisLevel: CrisisLevel?
        
        init(id: String = UUID().uuidString, role: String, text: String, timestamp: Date = Date(), crisisLevel: CrisisLevel? = nil) {
            self.id = id
            self.role = role
            self.text = text
            self.timestamp = timestamp
            self.crisisLevel = crisisLevel
        }
    }
}

// MARK: - Conversation Metadata

struct ConversationMetadata: Codable {
    var crisisLevel: CrisisLevel?
    var crisisSubtype: String?
    var drugDiscussionFlag: Bool
    var dependencyWarningCount: Int
    var farewellSuspect: Bool
    var lastCrisisTriggeredAt: Date?
    var consecutiveTriggerCount: Int
    
    init(crisisLevel: CrisisLevel? = nil, crisisSubtype: String? = nil, drugDiscussionFlag: Bool = false, dependencyWarningCount: Int = 0, farewellSuspect: Bool = false, lastCrisisTriggeredAt: Date? = nil, consecutiveTriggerCount: Int = 0) {
        self.crisisLevel = crisisLevel
        self.crisisSubtype = crisisSubtype
        self.drugDiscussionFlag = drugDiscussionFlag
        self.dependencyWarningCount = dependencyWarningCount
        self.farewellSuspect = farewellSuspect
        self.lastCrisisTriggeredAt = lastCrisisTriggeredAt
        self.consecutiveTriggerCount = consecutiveTriggerCount
    }
}

// MARK: - Safety Engine Results

struct PreLlmResult {
    let crisisLevel: CrisisLevel
    let injectionDetected: Bool
    let drugDiscussionTriggered: Bool
    let dependencyCount: Int
    let sanitizedText: String
    let shouldBlockLlm: Bool
    let fixedResponse: String?
    let crisisSubtype: String?
    
    init(crisisLevel: CrisisLevel = .normal, injectionDetected: Bool = false, drugDiscussionTriggered: Bool = false, dependencyCount: Int = 0, sanitizedText: String, shouldBlockLlm: Bool = false, fixedResponse: String? = nil, crisisSubtype: String? = nil) {
        self.crisisLevel = crisisLevel
        self.injectionDetected = injectionDetected
        self.drugDiscussionTriggered = drugDiscussionTriggered
        self.dependencyCount = dependencyCount
        self.sanitizedText = sanitizedText
        self.shouldBlockLlm = shouldBlockLlm
        self.fixedResponse = fixedResponse
        self.crisisSubtype = crisisSubtype
    }
}

struct PostLlmResult {
    let originalText: String
    let finalText: String
    let modifications: [PostLlmModification]
    let farewellSuspect: Bool
    let dependencyWarningInserted: Bool
    let drugDisclaimerInserted: Bool
    let diagnosticViolationTriggered: Bool
    let suggestionViolationTriggered: Bool
    
    init(originalText: String, finalText: String, modifications: [PostLlmModification] = [], farewellSuspect: Bool = false, dependencyWarningInserted: Bool = false, drugDisclaimerInserted: Bool = false, diagnosticViolationTriggered: Bool = false, suggestionViolationTriggered: Bool = false) {
        self.originalText = originalText
        self.finalText = finalText
        self.modifications = modifications
        self.farewellSuspect = farewellSuspect
        self.dependencyWarningInserted = dependencyWarningInserted
        self.drugDisclaimerInserted = drugDisclaimerInserted
        self.diagnosticViolationTriggered = diagnosticViolationTriggered
        self.suggestionViolationTriggered = suggestionViolationTriggered
    }
}

struct PostLlmModification: Identifiable, Codable {
    let id = UUID()
    let type: ModificationType
    let originalSnippet: String
    let replacementSnippet: String
    let ruleId: String
    
    enum ModificationType: String, Codable {
        case diagnostic_rewrite
        case suggestion_rewrite
        case farewell_check_inserted
        case dependency_check_inserted
        case drug_disclaimer_inserted
    }
}