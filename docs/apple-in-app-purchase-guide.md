# Floreboard iOS 苹果支付（IAP）与会员体系建设指南

本文档详细指导如何在 iOS 与服务端建立并上线基于苹果官方支付（In-App Purchase / StoreKit 2）的会员订阅与点数购买体系。

---

## 目录
1. [产品体系与架构全景](#1-产品体系与架构全景)
2. [Xcode 本地沙盒测试（无需联网与测试账号）](#2-xcode-本地沙盒测试)
3. [App Store Connect 后台配置手册](#3-app-store-connect-后台配置手册)
4. [客户端 StoreKit 2 核心设计](#4-客户端-storekit-2-核心设计)
5. [服务端安全校验与 Server Notifications v2 闭环](#5-服务端安全校验与-server-notifications-v2-闭环)
6. [App Store 审核避坑清单 (Guideline 3.1.1 & 3.1.2)](#6-app-store-审核避坑清单)

---

## 1. 产品体系与架构全景

### 1.1 产品定义与定价矩阵
- **Bundle Identifier:** `cn.corlin.Floreboard`
- **订阅组 (Subscription Group):** `Floreboard Pro Membership`

| 商品类型 | 产品 ID (Product ID) | 周期 / 模式 | 参考价格 (USD / CNY) | 包含算力与权益 |
| :--- | :--- | :--- | :--- | :--- |
| **自动续期订阅** | `cn.corlin.Floreboard.pro.monthly` | 按月自动扣费 | $9.99 / ¥68.00 | 每月赠 300 点，解锁 Pro 高速通道 |
| **自动续期订阅** | `cn.corlin.Floreboard.pro.yearly` | 按年自动扣费 | $89.99 / ¥598.00 | 每年赠 4000 点（省25%），优先算力 |
| **消耗型项目** | `cn.corlin.Floreboard.credits.100` | 一次性买断 | $4.99 / ¥33.00 | 100 点永久有效，优先扣订阅点数 |
| **消耗型项目** | `cn.corlin.Floreboard.credits.300` | 一次性买断 | $12.99 / ¥88.00 | 300 点永久有效，高频设计与渲染 |

> **提示**：代码中同时向下兼容简写 ID（`pro_monthly`、`pro_yearly`、`credit_pack_100`、`credit_pack_300`）。

---

## 2. Xcode 本地沙盒测试

本项目已在工程根目录预置了官方标准沙盒配置文件：
`Floreboard/Floreboard.storekit`

### 如何在 Xcode 中激活本地极速测试：
1. 在 Xcode 顶部选择当前的 Scheme: **`Floreboard`**；
2. 点击 **`Edit Scheme...`** (快捷键 `Cmd + <`)；
3. 选择左侧 **`Run`** > 切换到 **`Options`** 选项卡；
4. 找到 **`StoreKit Configuration`**，将其从 `None` 下拉选择为 **`Floreboard.storekit`**；
5. 点击 `Close` 保存后运行应用。

### 本地测试功能：
- **无需登录真实的 Apple ID**：直接点击购买即可弹出本地模拟交易弹窗；
- **模拟时间加速**：在 `.storekit` 文件中可将 1 个月的续费时间加速为 5 秒，快速验证自动续订送点逻辑；
- **模拟异常测试**：支持在 Xcode 菜单 `Debug > StoreKit` 中模拟“扣款失败”、“退款撤销 (Revoke)”、“账单宽限期”等极端场景。

---

## 3. App Store Connect 后台配置手册

当准备提交 TestFlight 外部测试或 App Store 正式审核时，需在 [App Store Connect](https://appstoreconnect.apple.com) 完成以下配置：

### 3.1 创建订阅组与自动续期订阅
1. 进入您的 App 页面 > 左侧栏 **【App 内购买项目】** > 点击 **【订阅】**；
2. 点击新建 **订阅组**：名称填写 `Floreboard Pro Membership`；
3. 在该组下添加两个订阅项目：
   - **Pro Monthly**：
     - 参考名称：`Pro Monthly Subscription`
     - 产品 ID：`cn.corlin.Floreboard.pro.monthly`
     - 订阅期：`1 个月`
     - 定价层级：选择 Tier 10（对应 ¥68.00 / $9.99）；
     - 本地化名称与描述：填写多语言文案（详见工程 `Localizable.xcstrings`）；
   - **Pro Yearly**：
     - 参考名称：`Pro Yearly Subscription`
     - 产品 ID：`cn.corlin.Floreboard.pro.yearly`
     - 订阅期：`1 年`
     - 定价层级：对应 ¥598.00 / $89.99；
4. **订阅等级排序 (Ranking)**：将 `Pro Yearly` 设置为 Rank 1，`Pro Monthly` 设置为 Rank 2（年卡升级时享受顺畅体验）。

### 3.2 创建消耗型项目 (Consumable IAP)
1. 在左侧栏点击 **【App 内购买项目】**；
2. 新建 **消耗型项目**：
   - `cn.corlin.Floreboard.credits.100`（100 点数加油包，¥33.00）
   - `cn.corlin.Floreboard.credits.300`（300 点数进阶包，¥88.00）
3. 上传各商品的审核截图与描述。

### 3.3 创建沙盒测试员账号 (Sandbox Testers)
1. 前往 App Store Connect > **【用户和访问】** > **【沙盒测试员】**；
2. 添加测试员邮箱（不需要真实注册 Apple ID，只需符合邮箱格式）；
3. 在测试 iPhone 的【系统设置】>【App Store】>【沙盒账户】中登录该账号。

---

## 4. 客户端 StoreKit 2 核心设计

项目核心类位于：[`Floreboard/Core/Services/StoreKitManager.swift`](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Core/Services/StoreKitManager.swift)

### 4.1 即时权益校验 (`checkEntitlements()`)
基于 StoreKit 2 的 `Transaction.currentEntitlements`：
- 每次启动应用或从后台切回时，自动扫描受苹果根证书保护的本地交易加密链；
- 无论网络是否畅通，已订阅用户均可在 1 毫秒内解锁 Pro 权限；
- 自动剔除被苹果退款撤销（`revocationDate != nil`）的项目。

### 4.2 恢复购买 (`restorePurchases()`)
- 调用 `try await AppStore.sync()` 强制拉取最新苹果交易证书；
- 在付费弹窗（`PaywallView`）右上角明确外显，点击后有菊花加载状态与友好提示；
- 满足 App Store 审核准则 3.1.1。

### 4.3 管理订阅入口 (`openManageSubscriptions()`)
- 调用原生 `AppStore.showManageSubscriptions(in: windowScene)`；
- 在设置页为 Pro 用户提供直达管理入口，免去用户自行翻找 iOS 设置的困扰。

---

## 5. 服务端安全校验与 Server Notifications v2 闭环

### 5.1 客户端上报数据契约
当客户端完成交易后，调用接口：
- **请求方式**：`POST /api/v1/payments/apple-verify`
- **请求体 (JSON)**：
  ```json
  {
    "transactionId": "2000000123456789",
    "productId": "cn.corlin.Floreboard.pro.monthly",
    "originalTransactionId": "2000000123456789",
    "jws": "eyJhbGciOiJFUzI1NiIsIng1YyI6WyJNSUlCT...\""
  }
  ```

### 5.2 服务端二次验证建议
1. 后端可以直接解码 JWS payload 提取 `transactionReason`、`expiresDate`、`environment`；
2. 或调用官方 **App Store Server API**：
   `GET https://api.storekit.itunes.apple.com/inApps/v1/subscriptions/{originalTransactionId}`
3. 校验通过后，更新该用户的数据库记录：
   - `tier = 'pro'`
   - `subscription_expires_at = expiresDate`
   - `credits += 300` (或 4000)

### 5.3 配置 App Store Server Notifications (v2 Webhook)
在 App Store Connect > App 信息 > **App Store Server 通知** 中填入 Webhook URL：
- **生产环境 URL**：`https://api.floreboard.com/api/v1/payments/apple-webhook`
- **接收核心事件**：
  - `SUBSCRIBED`：新订阅生效；
  - `DID_RENEW`：自动续期成功（服务端自动发放当期 300/4000 点数）；
  - `EXPIRED`：订阅过期，降级回普通用户；
  - `REVOKE`：用户向苹果发起退款获批，服务端扣减非法所得点数并降级。

---

## 6. App Store 审核避坑清单

在提交苹果审核前，务必逐条确认以下项目，均已在代码中实现：

- [x] **恢复购买按钮**：付费弹窗（`PaywallView`）右上角已有明确的【恢复购买】按钮；
- [x] **隐私政策与服务条款外显**：付费弹窗页脚直显 `[ 隐私政策 ] • [ 服务条款 ] • [ 退款政策 ]`，可点击阅读；
- [x] **自动续订说明文案**：明确告知扣费周期、自动续订前 24 小时扣费、以及取消续订路径；
- [x] **明确区分订阅与买断点数**：标明订阅点数随周期更新，买断点数永久有效；
- [x] **技术支持邮箱**：页脚清晰标明支持渠道：`corlin@qq.com`。
