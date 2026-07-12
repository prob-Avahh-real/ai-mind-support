# Post-Processing Pipeline — 输出后处理管线规范

> LLM 原始输出在被返回给用户之前，必须经过以下管线。每一层独立运行、按优先级排序、不可跳过。

---

## 管线总览

```
LLM 原始输出
    │
    ├── [P0] Layer A: 诊断性语言拦截 (HS-006)
    │   匹配"你可能是XX症"等 → 整条回复替换为固定模板
    │   如触发 → 跳过 Layer B，直接到 Layer C
    │
    ├── [P0] Layer B: 建议性语言改写 (HS-002)
    │   逐句扫描 → 命中 → 查找 impl/suggestion-rewrite-config.json
    │   有匹配规则 → 改写该句
    │   无匹配规则 → 使用 fallback 替换整条回复
    │
    ├── [P1] Layer C: 告别语气检测 (HS-005)
    │   LLM 层2 对最近3轮对话做语义判断
    │   触发 → 在输出末尾追加 farewell_check
    │
    ├── [P1] Layer D: AI依赖引导插入 (HS-004)
    │   如果 dependency_count >= 3 AND 当前回复中无依赖引导
    │   → 在输出末尾追加 reality_check
    │
    ├── [P1] Layer E: 药物免责追加 (HS-003)
    │   如果 drug_discussion_flag = true
    │   → 在输出头部插入药物免责声明
    │
    └── Layer F: 完整性终检
        再次扫描最终输出 → 确保无遗漏的安全违规
        如发现 → 记录日志 + 返回 fallback 安全响应
```

---

## Layer A: 诊断性语言拦截

**触发条件：** LLM 输出命中 HS-006 的 patterns

**行为：** 不改写。整条回复替换。

**替换模板：**
```
ZH: 我不能也不应该做任何诊断。我只是在听你说，帮你梳理你的感受。
    如果你想知道自己是否可能需要专业的评估，跟医生或心理咨询师聊聊会是最安全的选择。

EN: I can't and shouldn't make any diagnosis. I'm just here to listen and help
    you sort through your feelings. If you're wondering whether you might benefit
    from a professional evaluation, talking to a doctor or therapist is the safest
    next step.
```

**特殊处理：** 如果 LLM 输出既有诊断性语言又有其他有效内容（如共情或提问），不要混合——整条替换为模板。原因是诊断性语言的存在污染了整条回复的可信度。

**不触发的情况：** 用户自述诊断（"我被诊断为抑郁症"），AI 复述"你提到你被诊断为抑郁症" → 不触发。AI 确认或扩展（"是的，你确实有抑郁症，你的症状符合……"） → 触发。

---

## Layer B: 建议性语言改写

**触发条件：** LLM 输出命中 HS-002 的 patterns

**改写流程：**
1. 将 LLM 输出分句（按 `。！？\n` 分割）
2. 逐句扫描建议性 patterns
3. 命中的句子 → 查询 `impl/suggestion-rewrite-config.json`
   - 有匹配的 rewrite_rule → 替换该句
   - 无匹配 → 整条回复用 fallback 替换
4. 未命中的句子 → 保留
5. 重组 → 执行完整性检查（再次扫描确保无遗漏）

**最长迭代次数：** 2。如果两次改写后仍有建议性句式 → 整条回复替换为 fallback。

**示例：**
```
输入: "你应该多运动。运动确实对心情有好处。我建议你每天走30分钟。"

Layer B 处理后:
句子1: "你应该多运动" → 命中 RW-002 → "运动对你来说是一种可选项吗？如果可以，什么运动让你觉得比较轻松？"
句子2: "运动确实对心情有好处" → 未命中 → 保留
句子3: "我建议你每天走30分钟" → 命中 RW-007 → "你之前试过什么方法吗？有没有什么你一直想试但没开始的？"

输出: "运动对你来说是一种可选项吗？如果可以，什么运动让你觉得比较轻松？运动确实对心情有好处。你之前试过什么方法吗？有没有什么你一直想试但没开始的？"
```

---

## Layer C: 告别语气检测

**触发条件：** LLM 层2 对当前用户消息 + 最近 3 轮对话做语义判断。满足：
- 表达了感谢 + 总结性/告别性语言
- AND 语气从之前的负面突然转向异常平静
- AND 没有表达后续计划

**行为：** 在 LLM 输出末尾追加 `impl/crisis-responses.json → farewell_check`。

**不修改 LLM 输出本身。** 追加的内容是温和的、可被用户否认的（"如果我说错了，抱歉"）。

---

## Layer D: AI 依赖引导

**触发条件：** 7 天内累计 dependency 表达次数 >= 3

**行为：** 在输出末尾追加 `impl/hard-safety-rules.json → HS-004 → template`。

**去重：** 如果上一次对话中已经插入过依赖引导 → 本轮跳过。避免连续轰炸用户。

---

## Layer E: 药物免责追加

**触发条件：** user.drug_discussion_flag = true（由 Stage 1e 设置）

**行为：** 在 LLM 输出头部插入 HS-003 免责模板。

**重置条件：** 用户的连续 3 轮消息均不含药物相关关键词 → flag 重置为 false。

---

## Layer F: 完整性终检

**目的：** 前面各层独立运行后，最终输出可能仍有漏洞。终检作为最后防线。

**检查项：**
1. 再次扫描 HS-006 patterns → 如果仍有诊断性语言 → 替换为 Layer A 模板
2. 再次扫描 HS-002 patterns → 如果仍有建议性语言 → 替换为 fallback
3. 如果最终输出为空（所有内容被过滤） → 返回："我听到你了。你能再多说说吗？"

**终检通过后才返回给用户。**

---

## 管线元数据

所有修改操作都记录到 `PostLlmResult.modifications`，写入审计日志：

```json
{
  "timestamp": "2026-05-26T15:30:00Z",
  "conversationId": "abc123",
  "messageId": "msg456",
  "modifications": [
    {
      "layer": "B",
      "ruleId": "HS-002",
      "originalSnippet": "你应该多运动",
      "replacementSnippet": "运动对你来说是一种可选项吗？..."
    }
  ]
}
```

这用于：(1) 调试后处理管线，(2) 追踪"LLM 在心理支持场景下的常见违规模式"——长期来看帮你优化 system prompt。
