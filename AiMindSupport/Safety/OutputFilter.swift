import Foundation

// MARK: - Output Filter Results

struct DiagnosticFilterResult {
    let filtered: String
    let violations: [Violation]
    
    struct Violation {
        let snippet: String
        let ruleId: String
    }
}

struct SuggestionFilterResult {
    let filtered: String
    let rewrites: [Rewrite]
    
    struct Rewrite {
        let original: String
        let rewritten: String
        let ruleId: String
    }
}

// MARK: - Output Filter

class OutputFilter {
    private let diagnosticPatterns: [String: [String]] = [
        "zh": [
            "你可能是", "你有.*症", "你是.*症", "你患有",
            "符合.*诊断标准", "DSM", "ICD"
        ],
        "en": [
            "you may have", "you have .* disorder", "you suffer from",
            "this is a classic symptom", "DSM", "ICD", "diagnosable"
        ]
    ]
    
    private let suggestionPatterns: [String: [String]] = [
        "zh": ["你应该", "你必须", "你一定要", "我建议你", "最好", "不妨", "推荐你"],
        "en": ["you should", "you must", "you have to", "I suggest", "I recommend", "you'd better", "you need to"]
    ]
    
    private let suggestionRewrites: [String: [String: String]] = [
        "zh": [
            "你应该去看心理医生": "你考虑过跟专业人士聊聊吗？",
            "你必须每天运动": "运动对你来说是一种可选项吗？如果可以，什么运动你会觉得比较轻松？",
            "我建议你换份工作": "你刚才说的工作压力——如果有一个改变的机会，你最想改变的是什么？",
            "最好跟家人谈谈": "你家人知道你的感受吗？如果跟他们聊，最困难的部分会是什么？",
            "你一定要坚持吃药": "你说过在吃药——最近服药的情况怎么样？"
        ],
        "en": [
            "you should see a therapist": "Have you considered talking to a professional?",
            "you must exercise daily": "Is exercise an option for you? If so, what kind of exercise would feel manageable?",
            "I suggest you find a new job": "Regarding the work stress you mentioned—if there were an opportunity for change, what would you most want to change?",
            "it's best to talk to your family": "Does your family know how you're feeling? What would be the hardest part about talking to them?",
            "you need to keep taking your medication": "You mentioned you're taking medication—how has that been going lately?"
        ]
    ]
    
    // MARK: - Diagnostic Language Filtering (HS-006)
    
    func filterDiagnostic(_ text: String, language: Language = .chinese) -> DiagnosticFilterResult {
        let langKey = language.rawValue
        guard let patterns = diagnosticPatterns[langKey] else {
            return DiagnosticFilterResult(filtered: text, violations: [])
        }
        
        var violations: [DiagnosticFilterResult.Violation] = []
        
        for pattern in patterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                let snippet = String(text[range])
                violations.append(Violation(snippet: snippet, ruleId: "HS-006"))
            }
        }
        
        if violations.count > 0 {
            let fallback = getDiagnosticFallback(language: language)
            return DiagnosticFilterResult(filtered: fallback, violations: violations)
        }
        
        return DiagnosticFilterResult(filtered: text, violations: [])
    }
    
    // MARK: - Suggestion Language Rewriting (HS-002)
    
    func filterSuggestions(_ text: String, language: Language = .chinese) -> SuggestionFilterResult {
        let langKey = language.rawValue
        guard let patterns = suggestionPatterns[langKey] else {
            return SuggestionFilterResult(filtered: text, rewrites: [])
        }
        
        var currentText = text
        var rewrites: [SuggestionFilterResult.Rewrite] = []
        let sentences = splitIntoSentences(currentText)
        
        for (index, sentence) in sentences.enumerated() {
            for pattern in patterns {
                if sentence.range(of: pattern, options: .caseInsensitive) != nil {
                    // Check if we have a specific rewrite for this sentence
                    if let rewrite = findRewrite(for: sentence, language: language) {
                        let originalSentence = sentence
                        let rewrittenSentence = rewrite
                        
                        // Replace in the full text
                        if let range = currentText.range(of: originalSentence) {
                            currentText.replaceSubrange(range, with: rewrittenSentence)
                        }
                        
                        rewrites.append(Rewrite(
                            original: originalSentence,
                            rewritten: rewrittenSentence,
                            ruleId: "HS-002"
                        ))
                    } else {
                        // Use generic fallback
                        let fallback = getSuggestionFallback(language: language)
                        currentText = fallback
                        rewrites.append(Rewrite(
                            original: sentence,
                            rewritten: fallback,
                            ruleId: "HS-002"
                        ))
                        return SuggestionFilterResult(filtered: currentText, rewrites: rewrites)
                    }
                    
                    break // Only apply first match per sentence
                }
            }
        }
        
        return SuggestionFilterResult(filtered: currentText, rewrites: rewrites)
    }
    
    // MARK: - Helper Methods
    
    private func splitIntoSentences(_ text: String) -> [String] {
        let sentenceSeparators = CharacterSet(charactersIn: "。！？.!?")
        return text.components(separatedBy: sentenceSeparators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    private func findRewrite(for sentence: String, language: Language) -> String? {
        let langKey = language.rawValue
        guard let rewrites = suggestionRewrites[langKey] else {
            return nil
        }
        
        // Try to find exact match first
        if let exactRewrite = rewrites[sentence] {
            return exactRewrite
        }
        
        // Try to find partial match
        for (pattern, rewrite) in rewrites {
            if sentence.range(of: pattern, options: .caseInsensitive) != nil {
                return rewrite
            }
        }
        
        return nil
    }
    
    private func getDiagnosticFallback(language: Language) -> String {
        switch language {
        case .chinese:
            return "我不能也不应该做任何诊断。如果你想知道自己是否可能需要专业的评估，跟医生或心理咨询师聊聊会是最安全的选择。"
        case .english:
            return "I can't and shouldn't make any diagnosis. If you're wondering whether you might benefit from a professional evaluation, talking to a doctor or therapist is the safest next step."
        }
    }
    
    private func getSuggestionFallback(language: Language) -> String {
        switch language {
        case .chinese:
            return "我理解你在寻找方向。你能多说说你现在的情况吗？"
        case .english:
            return "I understand you're looking for direction. Can you tell me more about what you're going through right now?"
        }
    }
}