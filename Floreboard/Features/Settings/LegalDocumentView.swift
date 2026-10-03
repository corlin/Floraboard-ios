//
//  LegalDocumentView.swift
//  Floreboard
//
//  Native in-app legal document viewer conforming to AppTheme design tokens.
//  100% synchronized with floreboard-web (https://floreboard.com).
//

import SwiftUI

// 法律条文正文按段落保持为单行字符串，便于与网页版（docs/legal）逐字对照，不做折行
// swiftlint:disable line_length

struct LegalDocumentView: View {
  let documentType: LegalDocumentType
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var loc: LocalizationManager

  var body: some View {
    NavigationStack {
      ZStack {
        AppTheme.background
          .ignoresSafeArea()

        ScrollView {
          VStack(alignment: .leading, spacing: 20) {
            // Header card
            HStack(spacing: 16) {
              ZStack {
                Circle()
                  .fill(AppTheme.primary.opacity(0.12))
                  .frame(width: 52, height: 52)
                Image(systemName: documentType.iconName)
                  .font(.system(size: 24, weight: .semibold))
                  .foregroundColor(AppTheme.primary)
              }

              VStack(alignment: .leading, spacing: 4) {
                Text(loc.t(documentType.titleKey))
                  .font(AppTheme.serifFont(size: 20, weight: .bold))
                  .foregroundColor(AppTheme.foreground)

                Text("floreboard.com • \(loc.t("legal.support", ["email": LegalConfig.contactEmail]))")
                  .font(AppTheme.captionSmall)
                  .foregroundColor(AppTheme.mutedText)
              }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surfaceElevated)
            .cornerRadius(AppTheme.containerRadius)
            .overlay(
              RoundedRectangle(cornerRadius: AppTheme.containerRadius)
                .stroke(AppTheme.hairline, lineWidth: 1)
            )

            // Content Sections
            VStack(alignment: .leading, spacing: 18) {
              switch documentType {
              case .privacy:
                privacyContent
              case .terms:
                termsContent
              case .refund:
                refundContent
              }
            }
            .padding(18)
            .background(AppTheme.surfaceElevated)
            .cornerRadius(AppTheme.containerRadius)
            .overlay(
              RoundedRectangle(cornerRadius: AppTheme.containerRadius)
                .stroke(AppTheme.hairline, lineWidth: 1)
            )

            // Web Link Banner (floreboard.com)
            HStack {
              Image(systemName: "safari")
                .foregroundColor(AppTheme.primary)
              VStack(alignment: .leading, spacing: 2) {
                Text(loc.t("legal.openInBrowser"))
                  .font(AppTheme.sansFont(size: 14, weight: .semibold))
                  .foregroundColor(AppTheme.primary)
                Text(documentType.webURL.absoluteString)
                  .font(AppTheme.captionSmall)
                  .foregroundColor(AppTheme.mutedText)
              }
              Spacer()
              Image(systemName: "arrow.up.right")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.mutedText)
            }
            .padding(14)
            .background(AppTheme.surfaceElevated)
            .cornerRadius(12)
            .overlay(
              RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.hairline, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
              UIApplication.shared.open(documentType.webURL)
            }
            .padding(.bottom, 24)
          }
          .padding(20)
        }
      }
      .navigationTitle(loc.t(documentType.titleKey))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(loc.t("legal.done")) {
            dismiss()
          }
          .foregroundColor(AppTheme.primary)
          .font(AppTheme.sansFont(size: 16, weight: .semibold))
        }

        ToolbarItem(placement: .primaryAction) {
          Link(destination: documentType.webURL) {
            Image(systemName: "safari")
              .foregroundColor(AppTheme.primary)
          }
        }
      }
    }
  }

  // MARK: - Privacy Policy (Synchronized with floreboard-web)
  @ViewBuilder
  private var privacyContent: some View {
    legalSection(
      title: isZh ? "1. 收集的个人数据类型 (Personal Data Collected)" : "1. Personal Data We Collect",
      body: isZh
        ? "• 账户凭据：注册与登录时填写的电子邮箱地址、花店或工作室名称、加密哈希密码。\n• 花艺业务与资产数据：您录入的花材品种名称、真实库存数量、采购成本单价、花器型号及历史生成的插花方案参数。\n• 支付与金融数据：所有付费与订阅均由官方合规渠道安全承兑。敏感支付数据（如完整信用卡号、CVV 安全码）由专业清算方银行级加密处理，Floreboard 服务器绝不收集、不存储您的原始银行卡信息。\n• 技术与设备日志：访问 IP 地址、操作系统型号、操作时间戳与系统异常日志（用于系统稳定性与防欺诈风控）。"
        : "• Account Credentials: Email address, flower shop or studio name, and cryptographically hashed passwords.\n• Floristry Business Data: Flower varieties, inventory quantities, purchase costs, custom vessel profiles, and saved floral design drafts.\n• Billing & Payment Data: All transactions are processed securely. Financial details are tokenized by PCI-DSS compliant gateways; Floreboard never collects or stores raw credit card details on our servers.\n• Technical & Log Data: IP addresses, device identifiers, and diagnostic logs used for security monitoring and fraud prevention."
    )

    legalSection(
      title: isZh ? "2. 数据存储与安全保护机制 (Data Storage & Protection)" : "2. How Data is Stored and Protected",
      body: isZh
        ? "• 传输加密：全站数据交互强制采用 TLS 1.3 现代安全加密通道，防止中间人嗅探。\n• 静态存储加密：业务数据库采用行业级 AES-256 静态加密保护。\n• 权限与安全访问：严格遵循最小必要权限原则，限制内部工程团队访问生产数据。"
        : "• Encryption in Transit: All data exchanged is encrypted using modern TLS 1.3 cryptographic protocols.\n• Encryption at Rest: Production databases are secured with AES-256 standard encryption.\n• Access Controls: We enforce strict least-privilege administrative access to production systems."
    )

    legalSection(
      title: isZh ? "3. 第三方数据共享明细 (Third-Party Sharing)" : "3. Third-Party Data Sharing",
      body: isZh
        ? "Floreboard 严格限制数据向第三方的共享，仅出于提供核心服务的必要性与受信处理方合作：\n• 支付结算服务商：安全承兑全球结账、处理销售税与增值税合规、防止金融欺诈。\n• 云计算与存储服务商：Cloudflare（提供全球边缘网络加速与分布式数据库安全）。\n• AI 图像与推理模型服务商：Google Gemini (Nano Banana)、FLUX.1、OpenAI GPT Image、Seedream（仅处理生成方案所需的提示词与花材参数，绝不出售您的私有业务资产，亦不将您的数据用于公共基础模型训练）。"
        : "We share data only with trusted infrastructure and service providers essential to operating our platform:\n• Payment Processors: Secure payment processing, tax compliance, and billing management.\n• Cloud Infrastructure: Cloudflare (edge hosting, DDoS protection, database persistence).\n• AI Inference Processors: Google Gemini (Nano Banana), FLUX.1 (Black Forest Labs), OpenAI GPT Image, Seedream (strictly for processing design prompts and image rendering; your proprietary assets are never sold or used for public AI training)."
    )

    legalSection(
      title: isZh ? "4. 用户数据权利与账户注销 (User Data Rights & Account Deletion)" : "4. User Data Rights & Account Cancellation",
      body: isZh
        ? "依据 GDPR、CCPA 及相关隐私法规，您享有以下法定权利：\n• 访问权 (Right of Access)：随时查阅并导出关于您的账户与业务数据副本。\n• 更正权 (Right to Rectification)：在个人“设置”中自行更新不准确的信息。\n• 删除权与账户注销 (Right to Erasure)：有权随时申请彻底注销您的 Floreboard 账户并清除所有关联数据。\n• 时效承诺：发送申请邮件至 corlin@qq.com，我们承诺在收到申请后 30 日内核验身份并从生产数据库中永久物理擦除您的个人识别信息与历史数据。"
        : "In accordance with GDPR, CCPA, and international data protection laws, you possess the following rights:\n• Right of Access: You may request a copy of all personal and project data.\n• Right to Rectification: You can update inaccurate account details in Settings or by contacting us.\n• Right to Erasure & Account Cancellation: You may request complete, permanent deletion of your account and records.\n• Timeline SLA: Email corlin@qq.com. We verify identity and permanently purge your data from production systems within 30 days."
    )

    legalSection(
      title: isZh ? "5. 本地离线存储与 Cookie 说明" : "5. Cookies and Local Storage",
      body: isZh
        ? "Floreboard 使用本地存储以实现花材库存的毫秒级离线读取与方案草稿缓存。我们仅使用维持登录态会话与界面语言偏好所必需的功能项，绝不投放任何第三方侵入式广告追踪。"
        : "We use local storage to enable offline draft caching and fast catalog loading. We deploy only essential session mechanisms necessary to maintain authentication and language preferences, without third-party advertising trackers."
    )

    legalSection(
      title: isZh ? "6. 政策更新与联系专员" : "6. Privacy Inquiries and Contact Information",
      body: isZh
        ? "本政策若发生重大修改，我们将在系统显著位置提前公告。数据保护与隐私事务专员邮箱：corlin@qq.com。"
        : "For any questions or requests concerning your data privacy, contact our Data Protection Officer at corlin@qq.com."
    )
  }

  // MARK: - Terms of Service (Synchronized with floreboard-web)
  @ViewBuilder
  private var termsContent: some View {
    legalSection(
      title: isZh ? "1. 业务性质与纯数字化交付声明 (Digital Delivery Only)" : "1. Nature of Service & Pure Digital Delivery Only",
      body: isZh
        ? "• B2B 软件与生成式 AI 定位：Floreboard 为花艺师与花店工作室设计之 B2B 云端软件（SaaS）与生成式 AI 工作台，提供 AI 算法构图、配方预算核算与数字化渲染。\n• 100% 纯数字化交付：全站销售商品（含点数加油包与 Pro 订阅）均为 100% 虚拟数字化权益，付款后即时通过网络在线生效。\n• 排除实体鲜花与物流配送：Floreboard 绝不销售或寄送任何真实鲜花、盆栽植物、花瓶器皿或任何实体商品，亦不提供线下人工插花或现场布置劳务。所有效果图均为数字化概念草图。"
        : "• B2B SaaS & Generative AI Platform: Floreboard is a cloud-based software and generative AI platform designed for florists and botanical studios.\n• 100% Digital Delivery Only: All products (Pro Subscriptions and Credit Packs) are 100% digital software access and cloud compute credits, delivered immediately and electronically upon payment.\n• No Physical Goods or Logistics Fulfillment: Floreboard does NOT sell, distribute, or ship fresh flowers, living plants, floral supplies, or ceramic vases. All floral visuals generated are purely digital conceptual drafts."
    )

    legalSection(
      title: isZh ? "2. 账户注册与服务访问" : "2. Account Registration and Access",
      body: isZh
        ? "您必须创建账户方可使用 Floreboard 的高级 AI 插花设计、方案管理及云端同步服务。您需对保管自身账户凭证安全承担全责，若发现未经授权的账户访问，请立即通过 corlin@qq.com 通知我们。"
        : "You must register an account to access Floreboard design tools, inventory sync, and AI generation features. You are responsible for safeguarding your credentials. Notify us immediately at corlin@qq.com if you suspect unauthorized access."
    )

    legalSection(
      title: isZh ? "3. 点数体系与订阅规则" : "3. Credits and Subscription Plans",
      body: isZh
        ? "• 点数加油包 (Credit Packs)：所购积分永久有效，按次消耗。每次生成花艺方案消耗 1 点，超高清 4K 商业级渲染消耗 5 点。\n• Pro 订阅会员：按月 (¥68 / $9.99) 或按年 (¥598 / $89.99) 定期自动计费并充入相应配额。您可以随时管理或取消自动续订，取消后会员特权将持续至当前周期的截止日期。"
        : "• Credit Packs: Purchased credits are non-expiring and consumed per generation (1 credit per standard design generation, 5 credits per 4K high-resolution render).\n• Pro Subscriptions: Recurring monthly ($9.99/mo) or yearly ($89.99/yr) plans automatically allocate credits each billing cycle. You can cancel your subscription anytime via Settings to prevent future renewals."
    )

    legalSection(
      title: isZh ? "4. 底层生图 AI 模型披露 (Underlying AI Models)" : "4. Underlying AI Models Disclosure",
      body: isZh
        ? "为确保技术透明度与工业级设计水准，Floreboard 明确披露平台集成的底层生成式 AI 模型：\n• Google Gemini / Nano Banana：花材逻辑配比、结构化色彩提示词推论与方案推理。\n• FLUX.1 (Black Forest Labs)：4K 商业写实光影、高精细氛围与花瓣微距纹理渲染。\n• OpenAI GPT Image & Seedream：高并发备用管线与多元艺术风格生成。"
        : "Floreboard explicitly discloses the underlying generative AI models deployed on our platform:\n• Google Gemini / Nano Banana: Powers floral recipe reasoning, color harmony algorithms, and structured prompt synthesis.\n• FLUX.1 (Black Forest Labs): Deployed for photorealistic 4K commercial floral rendering and petal macro-texture generation.\n• OpenAI GPT Image & Seedream: Redundant secondary and stylistic generation pipelines ensuring high uptime."
    )

    legalSection(
      title: isZh ? "5. 严禁违规内容与六大禁止类别" : "5. Content Standards and Prohibited Categories",
      body: isZh
        ? "Floreboard 严禁用户上传、提示词生成或传播以下六类违禁内容：\n1. 色情成人 (Sexual/NSFW)\n2. 暴力血腥 (Violence/Gore)\n3. 仇恨言论 (Hate Speech)\n4. 危害儿童 (Child Unsafe)\n5. 深度伪造与冒用 (Deepfake/Impersonation)\n6. 侵害商标版权 (Copyright Infringement)"
        : "Floreboard strictly prohibits users from uploading, prompting, generating, or transmitting content in the following six categories:\n1. Sexual / NSFW Content\n2. Violence / Gore\n3. Hate Speech\n4. Child Unsafe Content (zero tolerance)\n5. Deepfake / Impersonation\n6. Copyright / Trademark Infringement"
    )

    legalSection(
      title: isZh ? "6. 违规处置措施、举报信箱与审核流程" : "6. Enforcement Actions & Moderation Process",
      body: isZh
        ? "• 处置措施：立即下架删除侵权违规内容、封禁账户、没收剩余点数且不予退费。\n• 举报信箱：corlin@qq.com（安全团队在 24 至 48 小时内完成核查与处置）。\n• 三道审核防护机制：前置提示词机审 + 生成后计算机视觉安全扫描 + 人工复核工单仲裁。"
        : "• Enforcement: Immediate content removal, account suspension/termination, forfeiture of credits without refund.\n• Reporting Email: corlin@qq.com (investigated within 24 to 48 hours).\n• Three-Tier Pipeline: Automated pre-generation prompt filtering + automated post-generation vision scanning + human safety escalation."
    )

    legalSection(
      title: isZh ? "7. 知识产权与 AI 成果归属" : "7. Intellectual Property & AI Generation Rights",
      body: isZh
        ? "• 用户资产归属：您上传的库存花材、定制花器及私人配置的所有权始终归属于您。\n• AI 商业权利：在适用法律允许的最大范围内，由 Floreboard 根据您需求生成的插花方案与渲染图像，其商业使用权归您所有，您可自由将其用于商业插花交付、花艺展示与客户提案。"
        : "• User Inputs: You retain full ownership of all flower inventory data, custom vessel designs, and store assets.\n• AI Commercial Rights: To the fullest extent permitted by applicable law, you own the commercial rights to floral design schemes and rendered images generated for your account for commercial floristry and marketing."
    )

    legalSection(
      title: isZh ? "8. 免责声明与责任限制 (Disclaimers & Limitation of Liability)" : "8. Disclaimers & Limitation of Liability",
      body: isZh
        ? "• 按“现状 (AS IS)”与“可用”基础提供：Floreboard 软件平台与 AI 算法均按照“现状”基础提供，不提供适销性、特定用途适用性或无错误的默示担保。AI 配比建议仅供花艺师参考，不构成对实际花材物理属性的绝对担保。\n• 排除衍生损害：在法律允许的最大范围内，排除任何间接、偶然、特殊或后果性利润损失赔偿责任。\n• 赔偿上限：累计最高赔偿责任总额不超过过去 12 个月内您实际支付的金额或 100 美元（以较高者为准）。"
        : "• Provided \"AS IS\" & \"AS AVAILABLE\": The platform and AI algorithms are provided without warranties of any kind. AI compositions and estimates are advisory inspiration and not craft guarantees.\n• Limitation of Consequential Damages: To the maximum extent permitted by law, Floreboard shall not be liable for indirect, incidental, or consequential damages.\n• Cap on Aggregate Liability: Cumulative liability is capped at the amount paid by you in the preceding 12 months or $100.00 USD (whichever is greater)."
    )

    legalSection(
      title: isZh ? "9. 条款修订与联系支持" : "9. Updates and Contact Support",
      body: isZh
        ? "我们可能会适时更新本服务条款。如有任何疑问或合规咨询，请联系官方客户支持邮箱：corlin@qq.com。"
        : "We may update these terms periodically. For inquiries regarding terms or compliance, contact support at corlin@qq.com."
    )
  }

  // MARK: - Refund Policy (Synchronized with floreboard-web)
  @ViewBuilder
  private var refundContent: some View {
    legalSection(
      title: isZh ? "1. 点数加油包 (Credit Packs) 退款细则" : "1. Credit Packs Refund Policy",
      body: isZh
        ? "• 7 天无理由退款（仅限未使用）：自购买之日起 7 个自然日内，若该笔订单所包含的点数完全未使用（消耗数为 0），您可申请全额退款。\n• 已消耗点数不可退：由于 AI 算法生成与 4K 超高清图像渲染在调用时即消耗算力云资源，若该充值包的点数已被部分消耗，则该订单整体不支持退款。\n• 永久有效原则：未消耗的点数永久保存在您的账户中，永不过期，您可留待后续任意时间使用。"
        : "• 7-Day Money-Back Guarantee (Unused Only): Full refund within 7 calendar days of purchase, provided none of the credits have been used.\n• Partially Consumed Credits: Because generative AI inference and 4K rendering incur real-time GPU compute expenses, credit packs with consumed credits are strictly non-refundable.\n• Non-Expiring: Unused credits never expire and remain safe in your account for future projects."
    )

    legalSection(
      title: isZh ? "2. Pro 订阅计划（月卡 / 年卡）取消与退款" : "2. Pro Subscriptions (Monthly & Yearly)",
      body: isZh
        ? "• 随时自主取消续费：您可以随时前往“设置 > 订阅管理”点击取消下个周期的自动扣费，或在 iPhone [系统设置 > Apple ID > 订阅] 中取消。取消后不会产生后续扣费。\n• 当期权益持续有效：取消订阅后，您当前的 Pro 特权与剩余可用额度将继续生效，直至当前计费周期最后一天终止。\n• 周期内退款条件：月度与年度订阅一经生效扣款，原则上不退还当期已生效周期的费用；若发生意外重复扣款或扣费 48 小时内且未消耗任何点数，可申请人工审核退款。"
        : "• Cancel Anytime: Cancel recurring subscription renewal at any time via Settings or iOS Settings > Apple ID > Subscriptions to prevent future charges.\n• Access Until Period End: Pro benefits and credit allocations remain active until the end of the current billing cycle.\n• Period Refunds: Billed periods are generally non-refundable unless duplicate charges occurred or an error was reported within 48 hours without credit usage."
    )

    legalSection(
      title: isZh ? "3. 服务异常与技术故障补偿保障" : "3. Technical Failures & Failure Protection",
      body: isZh
        ? "若因 Floreboard 系统服务中断、AI 模型网关超时或网络故障导致点数被扣除但未能生成方案或效果图，系统将自动进行点数冲正与回滚补全。若遇点数未自动补回，请直接联系官方客服 corlin@qq.com，我们将在 24 小时内核验日志并为您足额手动补发积分。"
        : "If a system disruption, gateway timeout, or backend error causes credits to be deducted without producing the requested design or render output, our system restores credits automatically. If credits are not automatically restored, reach out to corlin@qq.com and our team will credit your account within 24 hours."
    )

    legalSection(
      title: isZh ? "4. 退款申请流程与处理时限" : "4. Refund Application Process & SLA",
      body: isZh
        ? "• 申请方式：发送退款申请邮件至官方邮箱 corlin@qq.com（或通过 Apple 官方退款通道 reportaproblem.apple.com 提交）。\n• 邮件要求：请在邮件主题中注明【退款申请 + 订单号】，并在正文中说明注册邮箱、购买时间及申请退款原因。\n• 受理时效：客服人员将在 1 个工作日内审核您的申请；审核通过后，款项将原路退回至您的初始支付方式，通常在 3 至 5 个工作日内到账。"
        : "• Application: Email corlin@qq.com (or submit via Apple at reportaproblem.apple.com for In-App Purchases).\n• Subject Format: Please use '[Refund Request] Order #' and include your account email, timestamp, and reason.\n• Response SLA: Reviewed within 1 business day; upon approval, funds are returned to your original payment method within 3 to 5 business days."
    )

    legalSection(
      title: isZh ? "5. 争议与联系支持" : "5. Dispute Resolution & Inquiries",
      body: isZh
        ? "如对退款结果存在争议，我们将本着公平诚信原则与您协商沟通。如有任何退款相关疑问，请随时联系客户服务团队：corlin@qq.com。"
        : "For any questions or dispute inquiries regarding billing, reach out directly to our customer support team at corlin@qq.com."
    )
  }

  // MARK: - Helper Views
  private func legalSection(title: String, body: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(AppTheme.sansFont(size: 15, weight: .bold))
        .foregroundColor(AppTheme.foreground)

      Text(body)
        .font(AppTheme.sansFont(size: 13))
        .foregroundColor(AppTheme.mutedText)
        .lineSpacing(3)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var isZh: Bool {
    loc.currentLanguage == .zh
  }
}
// swiftlint:enable line_length
