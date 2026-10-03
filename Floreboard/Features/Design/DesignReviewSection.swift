//
//  DesignReviewSection.swift
//  Floreboard
//
//  专业校验：服务端用确定性规则（流派/场合/花材知识）检查方案，给出严重问题、建议与提示。
//  只读展示；文案按界面语言渲染（键名与网页端 knowledge.rule.* 一致）。
//

import SwiftUI

struct DesignReviewSection: View {
  let findings: DesignFindings

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Label(ProductionStrings.t("knowledge.title"), systemImage: "checkmark.shield")
        .font(AppTheme.sansFont(size: 14, weight: .semibold))
        .foregroundColor(AppTheme.foreground)
      Text(ProductionStrings.t("knowledge.subtitle"))
        .font(AppTheme.sansFont(size: 11))
        .foregroundColor(AppTheme.mutedText)

      let rows = findings.items.compactMap { finding -> (DesignFinding, String)? in
        let text = Self.render(finding)
        return text.isEmpty ? nil : (finding, text)
      }
      if rows.isEmpty {
        row(icon: "checkmark.seal.fill", color: AppTheme.success, text: ProductionStrings.t("knowledge.allClear"))
      } else {
        ForEach(rows, id: \.0.id) { finding, text in
          let style = Self.style(finding.level)
          row(icon: style.icon, color: style.color, text: text)
        }
      }
    }
  }

  private func row(icon: String, color: Color, text: String) -> some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: icon).foregroundColor(color).font(.system(size: 14)).padding(.top, 2)
      Text(text)
        .font(AppTheme.sansFont(size: 14))
        .foregroundColor(AppTheme.foreground)
        .fixedSize(horizontal: false, vertical: true)
      Spacer(minLength: 0)
    }
    .padding(10)
    .background(RoundedRectangle(cornerRadius: AppTheme.chipRadius, style: .continuous).fill(color.opacity(0.10)))
  }

  private static func style(_ level: DesignFinding.Level) -> (icon: String, color: Color) {
    switch level {
    case .error: return ("xmark.octagon.fill", AppTheme.danger)
    case .warn: return ("exclamationmark.triangle.fill", AppTheme.warning)
    case .info: return ("info.circle.fill", AppTheme.mutedText)
    }
  }

  /// 流派/季节参数是 id，先换成当前语言的名称；找不到对应文案时返回空串（该条不显示）
  static func render(_ finding: DesignFinding) -> String {
    var params = finding.params
    if let s = params["school"] { params["school"] = translated("knowledge.school.\(s)", fallback: s) }
    if let s = params["season"] { params["season"] = translated("knowledge.season.\(s)", fallback: s) }
    let key = "knowledge.rule.\(finding.id)"
    let text = ProductionStrings.t(key, params)
    return text == key ? "" : text
  }

  private static func translated(_ key: String, fallback: String) -> String {
    let text = ProductionStrings.t(key)
    return text == key ? fallback : text
  }
}

/// 历史列表卡片上的徽标：只在有严重问题或建议时出现，红色=含严重问题，琥珀色=仅建议
struct ReviewBadge: View {
  let findings: DesignFindings?

  var body: some View {
    if let reviewed = findings, reviewed.badgeCount > 0 {
      Label("\(reviewed.badgeCount)", systemImage: "exclamationmark.triangle.fill")
        .font(.caption2.bold())
        .foregroundColor(reviewed.errorCount > 0 ? .white : .black.opacity(0.8))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Capsule().fill(reviewed.errorCount > 0 ? AppTheme.danger : AppTheme.warning))
        .accessibilityLabel(
          ProductionStrings.t(
            "knowledge.badge.title",
            ["error": "\(reviewed.errorCount)", "warn": "\(reviewed.warnCount)", "info": "\(reviewed.infoCount)"]))
    }
  }
}
