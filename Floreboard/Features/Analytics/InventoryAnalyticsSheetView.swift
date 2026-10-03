import SwiftUI
import Charts

struct CategoryStat: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
}

struct InventoryAnalyticsSheetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var loc: LocalizationManager
    
    let inventory: [FlowerType]
    
    var totalValue: Double {
        inventory.reduce(0) { $0 + Double($1.quantity) * $1.unitCost }
    }
    
    var categoryData: [CategoryStat] {
        var counts: [String: Int] = ["main": 0, "secondary": 0, "foliage": 0]
        for flower in inventory {
            counts[flower.category.rawValue, default: 0] += flower.quantity
        }
        return counts.map { CategoryStat(category: $0.key, count: $0.value) }
            .sorted(by: { $0.count > $1.count })
    }
    
    var topFlowers: [FlowerType] {
        Array(inventory.sorted(by: { $0.quantity > $1.quantity }).prefix(5))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackgroundView()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Total Value Card
                        VStack(spacing: 8) {
                            Text("¥\(String(format: "%.2f", totalValue))")
                                .font(AppTheme.serifFont(size: 32, weight: .bold))
                                .foregroundColor(AppTheme.foreground)
                            Text(loc.t("analytics.inventory.total_value"))
                                .font(AppTheme.sansFont(size: 14))
                                .foregroundColor(AppTheme.mutedText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .glassmorphic()
                        
                        // Category Chart
                        VStack(alignment: .leading, spacing: 16) {
                            Text(loc.t("analytics.inventory.category_dist"))
                                .font(AppTheme.serifFont(size: 20, weight: .bold))
                                .foregroundColor(AppTheme.foreground)
                            
                            if #available(iOS 17.0, *) {
                                Chart(categoryData) { item in
                                    SectorMark(
                                        angle: .value("Count", item.count),
                                        innerRadius: .ratio(0.6),
                                        angularInset: 1.5
                                    )
                                    .cornerRadius(4)
                                    .foregroundStyle(by: .value("Category", categoryName(item.category)))
                                    .annotation(position: .overlay) {
                                        // swiftlint:disable:next empty_count - count 是数量（Int），不是集合
                                        if item.count > 0 {
                                            Text("\(item.count)")
                                                .font(.caption.bold())
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .frame(height: 250)
                                .chartLegend(position: .bottom, spacing: 20)
                            } else {
                                // Fallback for iOS 16
                                Chart(categoryData) { item in
                                    BarMark(
                                        x: .value("Count", item.count),
                                        y: .value("Category", categoryName(item.category))
                                    )
                                    .foregroundStyle(by: .value("Category", categoryName(item.category)))
                                }
                                .frame(height: 200)
                            }
                        }
                        .padding(20)
                        .glassmorphic()
                        
                        // Top 5 Flowers
                        VStack(alignment: .leading, spacing: 16) {
                            Text(loc.t("analytics.inventory.top5"))
                                .font(AppTheme.serifFont(size: 20, weight: .bold))
                                .foregroundColor(AppTheme.foreground)
                            
                            ForEach(Array(topFlowers.enumerated()), id: \.element.id) { index, flower in
                                HStack {
                                    Text("\(index + 1)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppTheme.primary.opacity(0.5))
                                        .frame(width: 24)
                                    
                                    Text(flower.name)
                                        .font(AppTheme.sansFont(size: 16, weight: .medium))
                                        .foregroundColor(AppTheme.foreground)
                                    
                                    Spacer()
                                    
                                    Text("\(flower.quantity)")
                                        .font(AppTheme.sansFont(size: 16, weight: .bold))
                                        .foregroundColor(AppTheme.primary)
                                }
                                .padding(.vertical, 8)
                                
                                if index < topFlowers.count - 1 {
                                    Divider().background(Color.white.opacity(0.1))
                                }
                            }
                        }
                        .padding(20)
                        .glassmorphic()
                    }
                    .padding()
                }
            }
            .navigationTitle(loc.t("analytics.inventory.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(loc.t("common.done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.primary)
                }
            }
        }
        .presentationDetents([.large])
    }
    
    func categoryName(_ raw: String) -> String {
        switch raw {
        case "main": return Tx.t("inventory.category.primary")
        case "secondary": return Tx.t("inventory.category.secondary")
        case "foliage": return Tx.t("inventory.category.foliage")
        default: return raw.capitalized
        }
    }
}
