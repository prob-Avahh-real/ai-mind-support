# BaaS 选型：HIPAA 合规后端

> **状态：** 草案 v1 — 待决策  
> **最后更新：** 2026-05-26  
> **核心问题：** 一个人做心理支持产品，怎么在"合规"和"运维负担"之间取最小阻力路径？

---

## 决策约束

| 约束 | 说明 |
|---|---|
| 独立开发者 | 没有运维团队，没有 DevOps，没有法务 |
| 心理支持产品 | 存储用户对话内容 —— 属于 PHI（受保护的健康信息）范畴 |
| 必须 HIPAA 合规 | 没有商量余地。不做合规的产品在这个赛道不应该存在。 |
| 预算有限 | SaaS 月费≤$100/月起步，逐步扩展 |
| 需要 BAA | 服务商必须愿意签署 Business Associate Agreement |
| 技术栈偏好 | 前后端不限，偏好 DX 好的方案 |

---

## 候选方案

### 方案 A：Firebase / Google Cloud（推荐）

**概述：** Firebase Auth + Firestore + Cloud Functions。一套全托管。

| 维度 | 评分 | 说明 |
|---|---|---|
| HIPAA 合规 | ✅ | Google Cloud 签署 BAA，覆盖 Firebase。需在 GCP Console 中启用。 |
| DX | ⭐⭐⭐⭐⭐ | Firebase 是 solo dev 的黄金标准。Auth 零配置，Firestore 实时同步，SDK 成熟。 |
| 运维负担 | ⭐⭐⭐⭐⭐ | 零服务器管理。自动扩容。 |
| 成本 | ⭐⭐⭐⭐ | 免费层慷慨。Firestore 按读写计费。估算：1000 活跃用户 ≈ $20-50/月。 |
| 供应商锁定 | ⚠️ | 高。Firestore 不是标准数据库，迁移成本大。 |
| BAA 流程 | 简单。GCP Console → Security → Compliance → 勾选 HIPAA → 签署 BAA。 |

**架构示意：**
```
用户 → Firebase Auth (认证)
     → Firestore (对话存储、用户档案)
     → Cloud Functions (API 层、安全检测引擎)
     → OpenAI/Anthropic API (LLM，无 PHI 发送，或脱敏后发送)
```

**需要注意的坑：**
- Firestore 的复合查询限制多。如果未来需要复杂搜索（"搜索所有提到'焦虑'的对话"），可能需要 Elasticsearch 或 Algolia 的补充。
- Firebase Admin SDK 在 Cloud Functions 中运行时，需确保 region 设置与 Firestore 一致。
- Cloud Functions 冷启动：安全检测引擎必须在冷启动后仍能正常加载关键词列表。

**BAA 签署步骤（2026 年）：**
1. 进入 GCP Console → IAM & Admin → Settings
2. 找到 "HIPAA Compliance" 部分
3. 确认你的项目使用了 Google 支持 HIPAA 的服务（Firestore, Cloud Functions 等）
4. 勾选并签署 BAA
5. 重要：签署 BAA 后，**不要**在非 HIPAA 覆盖的 GCP 服务中使用 PHI

---

### 方案 B：AWS（Cognito + DynamoDB + Lambda）

**概述：** 自己搭，但 AWS 的托管服务做底座。

| 维度 | 评分 | 说明 |
|---|---|---|
| HIPAA 合规 | ✅ | AWS 签署 BAA，覆盖大多数核心服务 |
| DX | ⭐⭐⭐ | 不如 Firebase 直观。Cognito 的文档混乱，Amplify CLI 不稳定。 |
| 运维负担 | ⭐⭐⭐ | 需要配置 IAM、VPC、安全组。初始设置约 2-3 天（有经验的话）。 |
| 成本 | ⭐⭐⭐⭐ | DynamoDB on-demand 起步极便宜。估算：1000 用户 ≈ $10-30/月。 |
| 供应商锁定 | ⭐⭐⭐ | 中等。DynamoDB 专有但可迁移到 MongoDB Atlas。 |
| BAA 流程 | AWS Artifact → 在线签署。标准流程。 |

**什么情况下选 B 而不是 A：**
- 你已经有 AWS 使用经验，且不愿意学 Firebase。
- 你需要更细粒度的 IAM 控制。
- 你讨厌供应商锁定，AWS 至少提供了"迁移到另一个 AWS 服务"的路径。
- 产品未来可能扩展到需要 HIPAA + HITRUST 或其他认证。

---

### 方案 C：不要用（排除清单）

| 方案 | 为什么不合适 |
|---|---|
| **Supabase** | HIPAA 合规仅在企业版（定制报价），不对个体开发者开放。 |
| **Vercel + Neon/PlanetScale** | Vercel 不签 BAA。Neon/PlanetScale 也不签。 |
| **Railway / Render / Fly.io** | 都不签 BAA。不是医疗场景的平台。 |
| **Netlify** | 不签 BAA。 |
| **MongoDB Atlas** | 需要 Enterprise 级别（$XX,XXX/年起）。 |
| **自托管 VPS + 加密** | 技术上可行但强烈不推荐——你需要管理加密密钥轮换、审计日志、访问控制、备份策略、入侵检测、合规文档。 |

---

## 推荐选择：方案 A（Firebase / Google Cloud）

**理由：**

1. **你只有一个人。** Firebase 的学习曲线是所有 HIPAA-compliant 方案里最低的。

2. **你的瓶颈是"做产品"不是"搭基建"。** 花 3 天在 AWS 上配 Cognito 和 IAM，不如花 2 小时在 Firebase Console 然后开始写对话流程。

3. **Firebase Auth 的心理支持加分项：** 支持匿名登录 → 匿名转永久账号（link account）。这对心理产品很重要——用户可能一开始不愿意注册，可以先匿名使用，建立信任后再关联邮箱。

4. **迁移成本是未来的问题。** 当你有了 1000 个付费用户、月收入 $10K+、有资源雇佣兼职运维时，再考虑迁移。现在先上线。

---

## Firestore 安全规则（心理支持产品的最小安全集）

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // 用户只能读写自己的档案
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // 用户只能读写自己的对话
    match /conversations/{conversationId} {
      allow read, write: if request.auth != null
        && request.auth.uid == resource.data.userId;

      // 创建对话时，userId 必须与当前用户匹配
      allow create: if request.auth != null
        && request.auth.uid == request.resource.data.userId;
    }

    // 对话中的消息
    match /conversations/{conversationId}/messages/{messageId} {
      allow read: if request.auth != null
        && get(/databases/$(database)/documents/conversations/$(conversationId)).data.userId == request.auth.uid;
      allow create: if request.auth != null
        && get(/databases/$(database)/documents/conversations/$(conversationId)).data.userId == request.auth.uid;
    }

    // 禁止访问任何未匹配的路径
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## LLM API 调用中的数据最小化策略

### 选择 1：发送对话给 LLM，但先脱敏（推荐起步用）

- 在发送前，用正则移除 PII（邮箱、电话、姓名如果可识别）
- 心理支持场景下：对话内容本身就是 PHI（情感状态 + 个人经历），技术上无法完全剥离。所以这个方案本质是："我们信任 OpenAI/Anthropic 的 HIPAA 合规声明 + 我们在传输层做了 TLS + 我们在法律层面有 BAA"。

**OpenAI API 的 HIPAA 合规现状：**
- OpenAI 签署 BAA（企业版和 API）。
- API 调用默认不用于训练（2024 年后，ChatGPT 免费/Plus 用户的对话**会**被用于训练；API 调用**不会**）。
- 重要：需要在 OpenAI 账户中启用 HIPAA 设置，并签署 BAA。

**Anthropic API 的 HIPAA 合规现状：**
- Anthropic 签署 BAA（需要联系 sales 或通过合规页面申请）。
- 同样，API 调用默认不用于训练。

### 选择 2：本地/专用模型（中期目标）

等你有了稳定的用户群和足够的收入后，可以考虑部署本地或专用实例的模型（如通过 AWS Bedrock 或 GCP Vertex AI），用户数据不离开你的基础设施。这解决了"第三方 LLM 提供商看到 PHI"的问题——但现阶段不要考虑。让你慢下来的第一因素是"没上线"，不是"不够合规"。

---

## 行动清单

- [ ] 创建 GCP 项目
- [ ] 开通 Firebase（Auth, Firestore, Cloud Functions, Hosting）
- [ ] 在 GCP Console 中签署 HIPAA BAA
- [ ] 配置 Firestore 安全规则（应用上述最小规则集）
- [ ] 在 Firestore 中启用 at-rest encryption（默认启用，确认即可）
- [ ] 配置 Cloud Functions 的 region 与 Firestore 一致
- [ ] 在 OpenAI/Anthropic 控制台签署 BAA（或确认 API 使用的合规性）
- [ ] 确认 audit logging 已启用（GCP Cloud Audit Logs）
- [ ] 设置预算告警（避免意外账单）
- [ ] 写一个文档：数据流转图（用户 → Firebase → Cloud Function → LLM API → 返回），标注每一步的加密和合规状态

---

## 面向审计的数据流转文档模板

```
数据流转图 v1 - [项目名]

1. 用户输入
   - 传输：TLS 1.3 (HTTPS)
   - 存储：N/A（尚未持久化）

2. Firebase Auth
   - 认证：Firebase Auth (OAuth 2.0 / 匿名)
   - 用户标识：Firebase UID（非 PII）

3. Firestore
   - 加密：at rest (AES-256, Google-managed keys)
   - 传输：TLS (gRPC)
   - 访问控制：Firestore Security Rules（用户隔离）
   - 审计：Cloud Audit Logs → Admin Read / Data Read / Data Write

4. Cloud Functions (安全检测引擎 + 业务逻辑)
   - 运行时环境：GCP-managed, isolated
   - 内存中处理 PHI：是（对话内容）
   - PHI 不写入函数日志：已配置（log masking）

5. LLM API (OpenAI / Anthropic)
   - 传输：TLS 1.3 (HTTPS)
   - 发送内容：脱敏后的对话文本（PII 移除，情感内容保留）
   - API 数据使用政策：不用于模型训练（已确认 + BAA 已签署）
   - 响应日志：不在 LLM 提供商侧持久化（API 调用配置）

6. 备份
   - Firestore 自动备份（GCP-managed）
   - 加密 at rest
   - 保留策略：[待定义]
```

---

## 版本记录

| 版本 | 日期 | 变更 |
|---|---|---|
| v1 | 2026-05-26 | 初稿。方案对比、Firebase 推荐、安全规则、数据流转模板。 |

## 待办

- [ ] 确认 OpenAI 或 Anthropic 的 BAA 签署流程的最新状态（2026 年可能已有变化）
- [ ] 确认目标运营地区（中国大陆 / 海外）对数据存储的管辖权要求
- [ ] 如面向中国大陆用户：需额外考虑数据不出境方案（GCP 中国区或国内合规替代方案）
