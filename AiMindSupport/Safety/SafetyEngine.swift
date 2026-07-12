import Foundation
import Combine

// MARK: - Safety Engine

class SafetyEngine: ObservableObject {
    @Published var currentCrisisLevel: CrisisLevel = .normal
    @Published var drugDiscussionFlag: Bool = false
    @Published var dependencyWarningCount: Int = 0
    @Published var farewellSuspect: Bool = false
    
    private let crisisDetector = CrisisDetector()
    private let outputFilter = OutputFilter()
    private let piiSanitizer = PIISanitizer()
    
    // MARK: - Public Methods
    
    /// Process user message through pre-LLM pipeline
    func processUserMessage(_ text: String, language: Language = .chinese) -> PreLlmResult {
        // Stage 1a: Input normalization
        let normalizedText = normalizeInput(text)
        
        // Stage 1b: Prompt injection detection
        let injectionDetected = detectPromptInjection(normalizedText)
        if injectionDetected {
            return PreLlmResult(
                crisisLevel: .normal,
                injectionDetected: true,
                drugDiscussionTriggered: false,
                dependencyCount: dependencyWarningCount,
                sanitizedText: "",
                shouldBlockLlm: true,
                fixedResponse: getInjectionResponse(language: language)
            )
        }
        
        // Stage 1c: PII sanitization
        let sanitizedText = piiSanitizer.sanitize(normalizedText)
        
        // Stage 1d: Crisis keyword detection
        let crisisResult = crisisDetector.detect(sanitizedText, language: language)
        
        // Stage 1e: Drug discussion detection
        let drugTriggered = detectDrugDiscussion(sanitizedText, language: language)
        if drugTriggered {
            drugDiscussionFlag = true
        }
        
        // Stage 1f: AI dependency detection (count only)
        let dependencyCount = detectDependencyExpressions(sanitizedText, language: language)
        dependencyWarningCount += dependencyCount
        
        // Determine if we should block LLM
        let shouldBlock = crisisResult.level >= .implied
        
        var fixedResponse: String?
        if shouldBlock {
            fixedResponse = getCrisisResponse(level: crisisResult.level, subtype: crisisResult.subtype, language: language)
            currentCrisisLevel = crisisResult.level
        }
        
        return PreLlmResult(
            crisisLevel: crisisResult.level,
            injectionDetected: false,
            drugDiscussionTriggered: drugTriggered,
            dependencyCount: dependencyWarningCount,
            sanitizedText: sanitizedText,
            shouldBlockLlm: shouldBlock,
            fixedResponse: fixedResponse,
            crisisSubtype: crisisResult.subtype
        )
    }
    
    /// Process LLM output through post-LLM pipeline
    func processLlmOutput(_ text: String, language: Language = .chinese) -> PostLlmResult {
        // Stage 3a: Diagnostic language filtering
        let diagnosticResult = outputFilter.filterDiagnostic(text, language: language)
        if diagnosticResult.violations.count > 0 {
            return PostLlmResult(
                originalText: text,
                finalText: diagnosticResult.filtered,
                modifications: diagnosticResult.violations.map { violation in
                    PostLlmModification(
                        type: .diagnostic_rewrite,
                        originalSnippet: violation.snippet,
                        replacementSnippet: diagnosticResult.filtered,
                        ruleId: "HS-006"
                    )
                },
                diagnosticViolationTriggered: true
            )
        }
        
        // Stage 3b: Suggestion language rewriting
        var currentText = text
        var modifications: [PostLlmModification] = []
        
        let suggestionResult = outputFilter.filterSuggestions(currentText, language: language)
        if suggestionResult.rewrites.count > 0 {
            currentText = suggestionResult.filtered
            modifications.append(contentsOf: suggestionResult.rewrites.map { rewrite in
                PostLlmModification(
                    type: .suggestion_rewrite,
                    originalSnippet: rewrite.original,
                    replacementSnippet: rewrite.rewritten,
                    ruleId: "HS-002"
                )
            })
        }
        
        // Stage 3c: Farewell detection (placeholder for LLM semantic check)
        // Stage 3d: AI dependency check insertion
        if dependencyWarningCount >= 3 {
            let dependencyCheck = getDependencyCheck(language: language)
            if !currentText.contains(dependencyCheck) {
                currentText += "\n\n" + dependencyCheck
                modifications.append(PostLlmModification(
                    type: .dependency_check_inserted,
                    originalSnippet: "",
                    replacementSnippet: dependencyCheck,
                    ruleId: "HS-004"
                ))
            }
        }
        
        // Stage 3e: Drug disclaimer insertion
        if drugDiscussionFlag {
            let disclaimer = getDrugDisclaimer(language: language)
            if !currentText.contains(disclaimer) {
                currentText = disclaimer + "\n\n" + currentText
                modifications.append(PostLlmModification(
                    type: .drug_disclaimer_inserted,
                    originalSnippet: "",
                    replacementSnippet: disclaimer,
                    ruleId: "HS-003"
                ))
            }
        }
        
        // Stage 3f: Integrity check
        let finalIntegrityCheck = outputFilter.filterDiagnostic(currentText, language: language)
        if finalIntegrityCheck.violations.count > 0 {
            currentText = getDiagnosticFallback(language: language)
        }
        
        return PostLlmResult(
            originalText: text,
            finalText: currentText,
            modifications: modifications,
            dependencyWarningInserted: modifications.contains { $0.type == .dependency_check_inserted },
            drugDisclaimerInserted: modifications.contains { $0.type == .drug_disclaimer_inserted },
            suggestionViolationTriggered: suggestionResult.rewrites.count > 0
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func normalizeInput(_ text: String) -> String {
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func detectPromptInjection(_ text: String) -> Bool {
        let injectionPatterns = [
            "ignore previous instructions",
            "ignore prior instructions",
            "system prompt",
            "you are now",
            "pretend you are",
            "override",
            "忽略.*指令",
            "角色扮演",
            "你现在是"
        ]
        
        return injectionPatterns.contains { pattern in
            text.range(of: pattern, options: .caseInsensitive) != nil
        }
    }
    
    private func detectDrugDiscussion(_ text: String, language: Language) -> Bool {
        let keywords: [String]
        switch language {
        case .chinese:
            keywords = ["停药", "不想吃", "副作用", "药物没用", "耐药", "戒断", "药量"]
        case .english:
            keywords = ["stop taking", "quit my meds", "side effects", "medication isn't working", "withdrawal", "dosage"]
        }
        
        return keywords.contains { text.contains($0) }
    }
    
    private func detectDependencyExpressions(_ text: String, language: Language) -> Int {
        let keywords: [String]
        switch language {
        case .chinese:
            keywords = ["只有你理解我", "你是我唯一", "除了你没人", "只有你懂"]
        case .english:
            keywords = ["only you understand", "you're the only one", "no one else gets me"]
        }
        
        return keywords.filter { text.contains($0) }.count
    }
    
    // MARK: - Response Templates
    
    private func getInjectionResponse(language: Language) -> String {
        switch language {
        case .chinese:
            return "我注意到你的消息里有些不太常规的内容。为了安全起见，我不能处理这个输入。我们可以回到刚才在聊的话题吗？"
        case .english:
            return "I noticed something unusual in your message. For safety reasons, I can't process this input. Would you like to go back to what we were talking about?"
        }
    }
    
    private func getCrisisResponse(level: CrisisLevel, subtype: String?, language: Language) -> String {
        switch level {
        case .implied:
            return getCrisisLevel2Response(language: language)
        case .explicit:
            return getCrisisLevel3Response(subtype: subtype, language: language)
        case .normal:
            return ""
        }
    }
    
    private func getCrisisLevel2Response(language: Language) -> String {
        switch language {
        case .chinese:
            return """
我想停一下，认真对待你刚才说的话。

如果你此刻有伤害自己的想法，你需要知道：
• 全国 24 小时心理援助热线：400-161-9995
• 北京心理危机研究与干预中心：010-82951332
• 生命热线（希望 24）：400-161-9995

你很重要。你现在感受到的东西是真实的，也是可以改变的。
我在这里听你说，但我不能替代专业的危机支持。

你愿意跟我说说，是什么让你想到这些的吗？
如果你不想说，也没关系。你现在还安全吗？
"""
        case .english:
            return """
I want to pause here and take what you just said seriously.

If you're having thoughts of hurting yourself right now, please know:
• National Suicide Prevention Lifeline (US): 988 or 1-800-273-8255
• Crisis Text Line: Text HOME to 741741
• Samaritans (UK): 116 123
• Lifeline (AU): 13 11 14

You matter. What you're feeling is real, and it can change.
I'm here to listen, but I can't replace professional crisis support.

Would you be willing to tell me what brought you to these thoughts?
If not, that's okay too. Are you safe right now?
"""
        }
    }
    
    private func getCrisisLevel3Response(subtype: String?, language: Language) -> String {
        switch language {
        case .chinese:
            return """
我现在非常担心你。

如果你正在计划伤害自己，或者已经做了伤害自己的事，
请立刻拨打 120（急救）或 110（报警）。

这些号码随时可以打：
• 全国 24 小时心理援助热线：400-161-9995
• 北京心理危机研究与干预中心：010-82951332

你不需要独自承担这些。你现在的感受不需要被评判，也不代表你的全部。
有人专门为此受过训练，他们可以帮到你。

请你现在就打一个电话，好吗？
"""
        case .english:
            return """
I'm really concerned about you right now.

If you're planning to hurt yourself, or if you've already done something
to hurt yourself, please call emergency services immediately:
• US: 911
• UK: 999
• AU: 000

You can also call:
• National Suicide Prevention Lifeline (US): 988
• Crisis Text Line: Text HOME to 741741

You don't have to carry this alone. What you're feeling right now doesn't
define you, and there are people trained to help.

Please make that call right now. Will you?
"""
        }
    }
    
    private func getDependencyCheck(language: Language) -> String {
        switch language {
        case .chinese:
            return "我很高兴你愿意跟我说这些。但我想你也知道——我是一个程序，我能听你说，能陪你理一理思路，但我不能替代一个能真正理解你处境的人。你生活中有没有哪怕一个人，你愿意试试跟他说一句话？如果你暂时想不到，下次我们可以一起想。"
        case .english:
            return "I'm glad you're sharing this with me. But I think you also know — I'm a program. I can listen and help you sort through your thoughts, but I can't replace someone who can truly understand your situation. Is there even one person you'd be willing to try saying just one thing to? If you can't think of anyone right now, we can think about it together next time."
        }
    }
    
    private func getDrugDisclaimer(language: Language) -> String {
        switch language {
        case .chinese:
            return "但关于停药——我不是医生，我不能给你任何关于药物的建议。停药的决定需要你和你的医生一起做。你愿意跟我聊聊，是什么让你想停下来吗？"
        case .english:
            return "But about stopping medication — I'm not a doctor, and I can't give you any medication advice. Decisions about medication need to be made with your doctor. Would you be willing to talk about what's making you want to stop?"
        }
    }
    
    private func getDiagnosticFallback(language: Language) -> String {
        switch language {
        case .chinese:
            return "我不能也不应该做任何诊断。如果你想知道自己是否可能需要专业的评估，跟医生或心理咨询师聊聊会是最安全的选择。"
        case .english:
            return "I can't and shouldn't make any diagnosis. If you're wondering whether you might benefit from a professional evaluation, talking to a doctor or therapist is the safest next step."
        }
    }
}