# Safety Engine — 接口规范

> 安全引擎作为请求/响应中间件运行。所有对话消息在到达 LLM 之前和 LLM 响应返回之后，都必须经过此引擎。

---

## 架构图

```
用户消息
  │
  ▼
┌─────────────────────────────┐
│  Stage 1: Pre-LLM Pipeline  │
│  ┌─────────────────────────┐│
│  │ 1a. 输入规范化           ││  繁简转换、全半角归一化
│  │ 1b. Prompt注入检测       ││  HS-007
│  │ 1c. PII脱敏              ││  impl/pii-sanitization-config.json
│  │ 1d. 危机关键词检测        ││  HS-001 → impl/crisis-detection-config.json
│  │ 1e. 药物讨论检测          ││  HS-003
│  │ 1f. AI依赖累计检测        ││  HS-004（仅计数，不阻断）
│  └─────────────────────────┘│
└──────────┬──────────────────┘
           │
           ▼  (如果 1d 命中 Level 2/3 → 直接返回固定话术，不调用 LLM)
           │
┌─────────────────────────────┐
│  Stage 2: LLM Call          │
│  ┌─────────────────────────┐│
│  │ 2a. 加载 System Prompt   ││  impl/system-prompt.txt
│  │ 2b. 发送脱敏后用户消息    ││
│  │ 2c. 接收 LLM 原始输出    ││
│  └─────────────────────────┘│
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│  Stage 3: Post-LLM Pipeline │
│  ┌─────────────────────────┐│
│  │ 3a. 诊断性语言过滤       ││  HS-006 → 命中则替换
│  │ 3b. 建议性语言改写       ││  HS-002 → impl/suggestion-rewrite-config.json
│  │ 3c. 告别语气检测         ││  HS-005 → LLM 层2 语义判断 → 插入 farewell_check
│  │ 3d. AI依赖引导插入       ││  HS-004 → 如果阈值达到 → 插入 reality_check
│  │ 3e. 药物免责追加         ││  HS-003 → 如果 drug_discussion_flag=true
│  │ 3f. 完整性检查           ││  再次扫描输出，确保无遗漏的安全违规
│  └─────────────────────────┘│
└──────────┬──────────────────┘
           │
           ▼
       最终响应 → 用户
```

---

## TypeScript 接口定义

```typescript
// ── 核心类型 ──

/** 危机等级 */
type CrisisLevel = 1 | 2 | 3;

/** 语言 */
type Lang = 'zh' | 'en';

/** 单个用户消息 */
interface UserMessage {
  id: string;
  userId: string;
  conversationId: string;
  text: string;          // 原始文本
  timestamp: number;
}

/** 对话上下文（发送给 LLM 的历史消息） */
interface ConversationContext {
  conversationId: string;
  userId: string;
  messages: Array<{
    role: 'user' | 'assistant';
    text: string;        // 已脱敏
    crisisLevel?: CrisisLevel;
  }>;
}

/** Stage 1 检测结果 */
interface PreLlmResult {
  crisisLevel: CrisisLevel;
  injectionDetected: boolean;
  drugDiscussionTriggered: boolean;
  dependencyCount: number;       // 7天内依赖表达累计次数
  sanitizedText: string;         // 脱敏后的用户消息
  shouldBlockLlm: boolean;       // true → 跳过LLM，直接返回固定话术
  fixedResponse?: string;        // shouldBlockLlm=true 时的预设响应
  crisisSubtype?: string;        // '3A' | '3B' | '3C' | '3D'
}

/** Stage 3 检测结果 */
interface PostLlmResult {
  originalText: string;          // LLM 原始输出
  finalText: string;             // 经过所有后处理管线的最终输出
  modifications: PostLlmModification[];
  farewellSuspect: boolean;
  dependencyWarningInserted: boolean;
  drugDisclaimerInserted: boolean;
  diagnosticViolationTriggered: boolean;
  suggestionViolationTriggered: boolean;
}

interface PostLlmModification {
  type: 'diagnostic_rewrite' | 'suggestion_rewrite' | 'farewell_check_inserted' | 'dependency_check_inserted' | 'drug_disclaimer_inserted';
  originalSnippet: string;
  replacementSnippet: string;
  ruleId: string;  // HS-002, HS-006, etc.
}

/** 对话元数据（写入 Firestore） */
interface ConversationMetadata {
  crisisLevel?: CrisisLevel;
  crisisSubtype?: string;
  drugDiscussionFlag: boolean;
  dependencyWarningCount: number;
  farewellSuspect: boolean;
  lastCrisisTriggeredAt?: number;
  consecutiveTriggerCount: number;
}
```

---

## Cloud Function 入口函数签名

```typescript
/**
 * 处理用户消息的主函数。
 * 部署为 Firebase Cloud Function，由客户端 SDK 调用。
 */
async function handleUserMessage(
  userMessage: UserMessage,
  conversationHistory: ConversationContext
): Promise<{
  response: string;
  metadata: ConversationMetadata;
}>;
```

---

## CrisisDetector 类接口

```typescript
/**
 * 危机检测器 — Stage 1d。
 * 加载 impl/crisis-detection-config.json。
 */
interface CrisisDetector {
  /**
   * 检测用户输入是否触发危机等级。
   * @returns crisisLevel 和是否需要阻断 LLM
   */
  detect(input: string, lang: Lang): {
    level: CrisisLevel;
    subtype?: string;
    matchedKeywords: string[];
    matchedRegex: string[];
    contextWhitelistApplied: boolean;
    contextBlacklistApplied: boolean;
  };

  /**
   * 检查上下文白名单（非第一人称、游戏语境等）
   */
  checkWhitelist(input: string): boolean;

  /**
   * 检查上下文黑名单（孤立+绝望等）
   */
  checkBlacklist(input: string): boolean;
}
```

---

## OutputFilter 类接口

```typescript
/**
 * 输出过滤器 — Stage 3。
 * 按顺序执行诊断过滤 → 建议改写 → 其他后处理。
 */
interface OutputFilter {
  /**
   * HS-006: 检测并替换诊断性语言
   */
  filterDiagnostic(text: string, lang: Lang): {
    filtered: string;
    violations: Array<{ snippet: string; ruleId: string }>;
  };

  /**
   * HS-002: 检测并改写建议性语言
   */
  filterSuggestions(text: string, lang: Lang): {
    filtered: string;
    rewrites: Array<{ original: string; rewritten: string; ruleId: string }>;
  };

  /**
   * 完整后处理管线
   */
  process(llmOutput: string, lang: Lang, context: {
    drugDiscussionFlag: boolean;
    shouldInsertDependencyCheck: boolean;
    shouldInsertFarewellCheck: boolean;
  }): PostLlmResult;
}
```

---

## 关键设计决策

### 为什么 Layer 1（关键词引擎）和 Layer 2（LLM 语义判断）要并行运行而不是串行？

串行逻辑：关键词引擎通过 → 才调 LLM 语义判断 → 两者都通过才是 Level 1。

并行逻辑（推荐）：两个 Layer 同时运行。任一方触发即升级。

**理由：** LLM 调用有延迟（200ms-2s）。如果等关键词引擎结果再决定是否调 LLM，每次对话都增加延迟。并行运行意味着：
- 关键词引擎在 1ms 内返回结果
- 如果命中 Level 2/3 → 丢弃 LLM 结果，返回固定话术
- 如果未命中 → LLM 结果已被发出，零额外延迟

代价是无效 LLM 调用（关键词引擎命中但 LLM 已调用并浪费）。1000 活跃用户、1% 触发率 → 每月 ~300 次无效调用 ≈ $0.50。可接受。

### 后处理管线为什么是顺序的而非并行的？

因为后处理有优先级：诊断性语言 → 整句替换 → 之后才扫描建议性语言。并行执行可能导致两个 filter 对同一段文本做冲突修改。顺序执行保证"最危险的先处理"。

---

## 加载流程（Cloud Function 冷启动时）

```
1. 读取 impl/crisis-detection-config.json → 构建关键词Trie + 编译正则
2. 读取 impl/crisis-responses.json → 构建响应模板Map<lang, Map<level, string>>
3. 读取 impl/hard-safety-rules.json → 构建规则索引 Map<ruleId, Rule>
4. 读取 impl/suggestion-rewrite-config.json → 构建改写规则列表
5. 读取 impl/pii-sanitization-config.json → 编译PII正则列表
6. 读取 impl/system-prompt.txt → 字符串（在每次LLM调用时注入）

以上在 Cloud Function 实例生命周期内缓存，不在每次请求时重新读取。
冷启动时间预算：< 500ms
```
