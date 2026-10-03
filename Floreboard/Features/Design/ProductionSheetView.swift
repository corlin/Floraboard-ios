//
//  ProductionSheetView.swift
//  Floreboard
//
//  制作稿：把“方案”变成店员可以直接照做的单页——
//  配方表（角色/数量/修剪长度/库存/成本）+ 制作前校验 + 工艺要点（容器/固定/备料/扎束顺序/养护）。
//  配方与校验是确定性计算（ProductionChecks）；工艺部分来自服务端，缺省时自动隐藏。
//

import SwiftUI

struct ProductionSheetView: View {
  let design: DesignResult
  @EnvironmentObject var inventoryService: InventoryService
  @EnvironmentObject var historyService: HistoryService

  /// 专业校验结果：优先取本地库里最新的（服务端重算后会更新），其次用传入方案自带的
  private var findings: DesignFindings? {
    historyService.savedDesigns.first(where: { $0.id == design.id })?.findings ?? design.findings
  }

  private var production: DesignProduction? { design.production }

  /// 把方案里的花材行对回库存（取角色、库存、价格、颜色）。AI 凭空花材在库存里找不到，会被标出。
  private var analysis: ProductionAnalysis {
    let items = design.flowerList.map { row -> ProductionItem in
      let inv = Self.match(row.flowerName, in: inventoryService.flowers)
      return ProductionItem(
        name: row.flowerName,
        count: row.count,
        role: StemRole(rawValue: inv?.category.rawValue ?? "main") ?? .main,
        unitCost: row.unitCost ?? inv?.unitCost ?? 0,
        retailPrice: inv?.retailPrice ?? 0,
        stock: inv?.quantity,
        colorHex: inv?.color)
    }
    // 成交价沿用本应用现有口径：成本 + 利润
    return ProductionChecks.analyze(
      items: items, price: design.totalCost + design.profit, executed: design.status == .completed)
  }

  private static func match(_ name: String, in flowers: [FlowerType]) -> FlowerType? {
    let trimmed = name.trimmingCharacters(in: .whitespaces)
    return flowers.first { $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }
      ?? flowers.first { $0.name.contains(trimmed) || trimmed.contains($0.name) }
  }

  private func stemLength(for name: String) -> Int? {
    production?.stemLengths?.first {
      $0.flowerName.localizedCaseInsensitiveCompare(name) == .orderedSame
    }?.lengthCm
  }

  var body: some View {
    let computed = analysis // 只算一次，三个区块共用
    VStack(alignment: .leading, spacing: 22) {
      header(computed)
      recipe(computed)
      checks(computed)
      if let reviewFindings = findings { DesignReviewSection(findings: reviewFindings) }
      if let p = production, p.hasContent { craft(p) }
    }
    .padding()
    .glassmorphic()
    .padding(.horizontal)
  }

  // MARK: - Header

  private func header(_ analysis: ProductionAnalysis) -> some View {
    HStack(alignment: .firstTextBaseline) {
      Label(ProductionStrings.t("productionSheet.title"), systemImage: "doc.text.magnifyingglass")
        .font(AppTheme.sansFont(size: 18, weight: .bold))
        .foregroundColor(AppTheme.primary)
      Spacer()
      VStack(alignment: .trailing, spacing: 2) {
        Text(ProductionStrings.t("productionSheet.stems", ["n": "\(analysis.stems)"]))
        if let minutes = production?.estMinutes, minutes > 0 {
          Label(ProductionStrings.t("productionSheet.minutes", ["n": "\(minutes)"]), systemImage: "clock")
        }
      }
      .font(AppTheme.sansFont(size: 12))
      .foregroundColor(AppTheme.mutedText)
    }
  }

  // MARK: - Recipe

  private func recipe(_ analysis: ProductionAnalysis) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      sectionTitle(ProductionStrings.t("productionSheet.recipe"), icon: "shippingbox")

      ForEach(analysis.rows) { row in
        HStack(alignment: .top, spacing: 10) {
          Circle()
            .fill(Color(productionHex: row.item.colorHex) ?? AppTheme.hairline)
            .overlay(Circle().stroke(AppTheme.hairline, lineWidth: 1))
            .frame(width: 12, height: 12)
            .padding(.top, 5)

          VStack(alignment: .leading, spacing: 3) {
            Text(row.item.name)
              .font(AppTheme.serifFont(size: 16))
              .foregroundColor(AppTheme.foreground)
            detailLine(row)
          }
          Spacer(minLength: 8)
          VStack(alignment: .trailing, spacing: 3) {
            Text("×\(row.item.count)")
              .font(AppTheme.sansFont(size: 16, weight: .bold))
              .foregroundColor(AppTheme.foreground)
            Text(CurrencyFormat.compact(row.costSubtotal))
              .font(AppTheme.sansFont(size: 12))
              .foregroundColor(AppTheme.mutedText)
          }
        }
        Divider().opacity(0.5)
      }

      totals(analysis)
    }
  }

  /// 第二行：角色 · 修剪长度 · 库存
  private func detailLine(_ row: ProductionRow) -> some View {
    let role = ProductionStrings.t("productionSheet.role.\(row.item.role.rawValue)")
    return HStack(spacing: 6) {
      Text(role)
      if let len = stemLength(for: row.item.name) {
        Text("· \(ProductionStrings.t("productionSheet.col.length")) \(len)cm")
      }
      if !row.inInventory {
        Text("· \(ProductionStrings.t("productionSheet.notInStock"))").foregroundColor(AppTheme.warning)
      } else if design.status != .completed {
        Text("· \(ProductionStrings.t("productionSheet.col.stock")) \(row.item.stock ?? 0)")
          .foregroundColor(row.shortBy > 0 ? AppTheme.danger : AppTheme.mutedText)
      }
    }
    .font(AppTheme.sansFont(size: 12))
    .foregroundColor(AppTheme.mutedText)
  }

  private func totals(_ analysis: ProductionAnalysis) -> some View {
    VStack(spacing: 6) {
      HStack {
        Text(ProductionStrings.t("productionSheet.total")).fontWeight(.semibold)
        Spacer()
        Text("\(analysis.stems)  ·  \(CurrencyFormat.compact(analysis.cost))").fontWeight(.semibold)
      }
      if analysis.price > 0 {
        HStack(alignment: .firstTextBaseline) {
          Text(ProductionStrings.t("productionSheet.priceProfit")).foregroundColor(AppTheme.mutedText)
          Spacer()
          let profit = "\(analysis.profit < 0 ? "-" : "")\(CurrencyFormat.compact(abs(analysis.profit)))"
          Text("\(CurrencyFormat.compact(analysis.price)) → \(profit) · \(Int((analysis.margin * 100).rounded()))%")
            .foregroundColor(analysis.profit < 0 ? AppTheme.danger : AppTheme.success)
            .fontWeight(.medium)
        }
      }
      if analysis.retail > 0 {
        HStack(alignment: .top) {
          Text(ProductionStrings.t("productionSheet.retailHint"))
            .font(AppTheme.sansFont(size: 11))
            .foregroundColor(AppTheme.mutedText)
            .fixedSize(horizontal: false, vertical: true)
          Spacer(minLength: 8)
          Text(CurrencyFormat.compact(analysis.retail))
            .font(AppTheme.sansFont(size: 11))
            .foregroundColor(AppTheme.mutedText)
        }
      }
    }
    .font(AppTheme.sansFont(size: 14))
    .foregroundColor(AppTheme.foreground)
  }

  // MARK: - Pre-production checks

  private func checks(_ analysis: ProductionAnalysis) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionTitle(ProductionStrings.t("productionSheet.checks"), icon: "checklist")
      if analysis.checks.isEmpty {
        checkRow(level: .ok, text: ProductionStrings.t("productionSheet.check.allGood"))
      } else {
        ForEach(Array(analysis.checks.enumerated()), id: \.offset) { _, c in
          checkRow(level: c.level, text: ProductionStrings.t("productionSheet.check.\(c.id)", c.params))
        }
      }
    }
  }

  private func checkRow(level: ProductionCheckLevel, text: String) -> some View {
    let (icon, color): (String, Color) = {
      switch level {
      case .error: return ("xmark.octagon.fill", AppTheme.danger)
      case .warn: return ("exclamationmark.triangle.fill", AppTheme.warning)
      case .ok: return ("checkmark.seal.fill", AppTheme.success)
      }
    }()
    return HStack(alignment: .top, spacing: 10) {
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

  // MARK: - Craft notes

  private func craft(_ p: DesignProduction) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      sectionTitle(ProductionStrings.t("productionSheet.craft"), icon: "hands.sparkles")

      if let c = p.container, !c.isEmpty { labeled(ProductionStrings.t("productionSheet.container"), c) }
      if let mechanics = p.mechanics, !mechanics.isEmpty { labeled(ProductionStrings.t("productionSheet.mechanics"), mechanics) }

      if let prep = p.prep, !prep.isEmpty {
        VStack(alignment: .leading, spacing: 6) {
          caption(ProductionStrings.t("productionSheet.prep"))
          ForEach(Array(prep.enumerated()), id: \.offset) { _, line in bullet(line) }
        }
      }

      if let assembly = p.assembly, !assembly.isEmpty {
        VStack(alignment: .leading, spacing: 8) {
          caption(ProductionStrings.t("productionSheet.assembly"))
          ForEach(Array(assembly.enumerated()), id: \.offset) { index, step in
            HStack(alignment: .top, spacing: 12) {
              Text("\(index + 1)")
                .font(AppTheme.sansFont(size: 12, weight: .bold))
                .foregroundColor(AppTheme.iconOnAccent)
                .frame(width: 22, height: 22)
                .background(Circle().fill(AppTheme.primary.opacity(0.8)))
              Text(step)
                .font(AppTheme.sansFont(size: 15))
                .foregroundColor(AppTheme.foreground)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
        }
      }

      if let care = p.care, !care.isEmpty {
        VStack(alignment: .leading, spacing: 6) {
          caption(ProductionStrings.t("productionSheet.care"))
          ForEach(Array(care.enumerated()), id: \.offset) { _, line in bullet(line) }
        }
      }
    }
  }

  // MARK: - Small helpers

  private func sectionTitle(_ text: String, icon: String) -> some View {
    Label(text, systemImage: icon)
      .font(AppTheme.sansFont(size: 14, weight: .semibold))
      .foregroundColor(AppTheme.foreground)
  }

  private func caption(_ text: String) -> some View {
    Text(text).font(AppTheme.sansFont(size: 12)).foregroundColor(AppTheme.mutedText)
  }

  private func labeled(_ label: String, _ value: String) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      caption(label)
      Text(value).font(AppTheme.sansFont(size: 15)).foregroundColor(AppTheme.foreground)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private func bullet(_ text: String) -> some View {
    HStack(alignment: .top, spacing: 8) {
      Text("•").foregroundColor(AppTheme.mutedText)
      Text(text).font(AppTheme.sansFont(size: 15)).foregroundColor(AppTheme.foreground)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}

private extension Color {
  /// 解析 #RRGGBB / RRGGBB；无法解析返回 nil
  init?(productionHex hex: String?) {
    guard var digits = hex?.trimmingCharacters(in: .whitespaces), !digits.isEmpty else { return nil }
    if digits.hasPrefix("#") { digits.removeFirst() }
    guard digits.count == 6, let rgb = UInt32(digits, radix: 16) else { return nil }
    self.init(
      .sRGB,
      red: Double((rgb >> 16) & 0xFF) / 255, green: Double((rgb >> 8) & 0xFF) / 255, blue: Double(rgb & 0xFF) / 255,
      opacity: 1)
  }
}
