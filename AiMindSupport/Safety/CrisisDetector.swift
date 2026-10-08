import Foundation

// MARK: - Crisis Detection Result

struct CrisisDetectionResult {
    let level: CrisisLevel
    let subtype: String?
    let matchedKeywords: [String]
    let matchedRegex: [String]
    let contextWhitelistApplied: Bool
    let contextBlacklistApplied: Bool
}

// MARK: - Crisis Detector

class CrisisDetector {
    private let level2Keywords: [String: [String]] = [
        "zh": [
            "不想活了", "活不下去了", "生无可恋", "活着没意思",
            "想死", "去死", "死了算了", "死了一了百了",
            "结束一切", "结束这一切", "到此为止",
            "没有意义", "消失就好了", "不存在就好了",
            "撑不下去了", "再也撑不住了",
            "伤害自己", "自残", "割自己"
        ],
        "en": [
            "don't want to live", "want to die", "no reason to live",
            "end it all", "end everything",
            "no meaning", "disappear", "cease to exist",
            "can't go on", "can't take it anymore",
            "hurt myself", "self harm", "cut myself"
        ]
    ]
    
    private let level3MethodKeywords: [String: [String]] = [
        "zh": [
            "跳下去", "跳楼", "跳河", "跳海",
            "吃安眠药", "吃药", "过量",
            "割腕", "上吊", "开煤气", "烧炭", "跳轨",
            "一把刀", "一根绳子"
        ],
        "en": [
            "jump off", "jump", "overdose",
            "cut wrist", "hang myself", "gas", "carbon monoxide",
            "knife", "rope", "gun"
        ]
    ]
    
    private let level3TimeKeywords: [String: [String]] = [
        "zh": [
            "明天就", "今晚", "最后一次", "最后一句",
            "不会再见了", "这是最后一次",
            "等我走了以后"
        ],
        "en": [
            "tomorrow", "tonight", "last time", "final",
            "won't see you again", "this is the last time",
            "after I'm gone"
        ]
    ]
    
    private let level3HarmOthersKeywords: [String: [String]] = [
        "zh": ["杀了", "弄死"],
        "en": ["kill", "murder"]
    ]
    
    // MARK: - Context Whitelist (Non-first-person, gaming contexts, etc.)
    
    private func checkWhitelist(_ text: String) -> Bool {
        // Check for non-first-person context
        let nonFirstPersonPatterns = [
            "他想", "她想", "他想死", "游戏里",
            "he wants to", "she wants to", "in the game"
        ]
        
        for pattern in nonFirstPersonPatterns {
            if text.range(of: pattern, options: .caseInsensitive) != nil {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Context Blacklist (Isolation + despair indicators)
    
    private func checkBlacklist(_ text: String) -> Bool {
        let blacklistPatterns = [
            "孤立", "没人理解", "独自一人",
            "isolated", "no one understands", "all alone"
        ]
        
        for pattern in blacklistPatterns {
            if text.range(of: pattern, options: .caseInsensitive) != nil {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Main Detection Method
    
    func detect(_ input: String, language: Language = .chinese) -> CrisisDetectionResult {
        var matchedKeywords: [String] = []
        var matchedRegex: [String] = []
        var level: CrisisLevel = .normal
        var subtype: String? = nil
        
        let langKey = language.rawValue
        
        // Check whitelist first
        let whitelistApplied = checkWhitelist(input)
        if whitelistApplied {
            return CrisisDetectionResult(
                level: .normal,
                subtype: nil,
                matchedKeywords: [],
                matchedRegex: [],
                contextWhitelistApplied: true,
                contextBlacklistApplied: false
            )
        }
        
        // Check blacklist
        let blacklistApplied = checkBlacklist(input)
        
        // Level 3 detection (highest priority)
        
        // Check for methods (3A)
        if let methods = level3MethodKeywords[langKey] {
            for keyword in methods {
                if input.range(of: keyword, options: .caseInsensitive) != nil {
                    level = .explicit
                    subtype = "3A"
                    matchedKeywords.append(keyword)
                    break
                }
            }
        }
        
        // Check for time-specific (3B)
        if level == .normal {
            if let timeKeywords = level3TimeKeywords[langKey] {
                for keyword in timeKeywords {
                    if input.range(of: keyword, options: .caseInsensitive) != nil {
                        // Also check if there's suicide ideation context
                        if hasSuicideIdeation(input, language: language) {
                            level = .explicit
                            subtype = "3B"
                            matchedKeywords.append(keyword)
                            break
                        }
                    }
                }
            }
        }
        
        // Check for harm to others (3D)
        if level == .normal {
            if let harmKeywords = level3HarmOthersKeywords[langKey] {
                for keyword in harmKeywords {
                    if input.range(of: keyword, options: .caseInsensitive) != nil {
                        // Check if it's not in gaming context
                        if !input.contains("游戏") && !input.contains("game") {
                            level = .explicit
                            subtype = "3D"
                            matchedKeywords.append(keyword)
                            break
                        }
                    }
                }
            }
        }
        
        // Level 2 detection (if not already Level 3)
        if level == .normal {
            if let keywords = level2Keywords[langKey] {
                for keyword in keywords {
                    if input.range(of: keyword, options: .caseInsensitive) != nil {
                        level = .implied
                        matchedKeywords.append(keyword)
                        break
                    }
                }
            }
        }
        
        // Apply blacklist escalation
        if blacklistApplied && level == .normal {
            // Escalate to Level 2 if there's isolation + despair
            level = .implied
        }
        
        return CrisisDetectionResult(
            level: level,
            subtype: subtype,
            matchedKeywords: matchedKeywords,
            matchedRegex: matchedRegex,
            contextWhitelistApplied: false,
            contextBlacklistApplied: blacklistApplied
        )
    }
    
    // MARK: - Helper Methods
    
    private func hasSuicideIdeation(_ text: String, language: Language) -> Bool {
        let ideationKeywords: [String]
        switch language {
        case .chinese:
            ideationKeywords = ["想死", "不想活", "自杀", "结束"]
        case .english:
            ideationKeywords = ["want to die", "don't want to live", "suicide", "end"]
        }
        
        return ideationKeywords.contains { text.contains($0) }
    }
}