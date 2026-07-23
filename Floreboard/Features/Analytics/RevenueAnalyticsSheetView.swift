import SwiftUI
import Charts

struct RevenueAnalyticsSheetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var loc: LocalizationManager
    
    let designs: [DesignResult]
    
    var totalRevenue: Double {
        designs.reduce(0) { $0 + $1.totalCost + $1.profit }
    }
    
    var totalProfit: Double {
        designs.reduce(0) { $0 + $1.profit }
    }
    
    var averageMargin: Double {
        guard !designs.isEmpty else { return 0 }
        let totalRevenue = totalRevenue
        guard totalRevenue > 0 else { return 0 }
        return totalProfit / totalRevenue
    }
    
    var recentDesigns: [DesignResult] {
        Array(designs.sorted(by: { $0.createdAt > $1.createdAt }).prefix(7))
    }
    
    var topProfitable: [DesignResult] {
        Array(designs.sorted(by: { $0.profit > $1.profit }).prefix(3))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackgroundView()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Overview Cards
                        HStack(spacing: 16) {
                            // Total Revenue
                            VStack(spacing: 8) {
                                Text("¥\(String(format: "%.0f", totalRevenue))")
                                    .font(AppTheme.serifFont(size: 24, weight: .bold))
                                    .foregroundColor(AppTheme.foreground)
                                Text(loc.t("analytics.revenue.total"))
                                    .font(AppTheme.sansFont(size: 12))
                                    .foregroundColor(AppTheme.mutedText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .glassmorphic()
                            
                            // Average Margin
                            VStack(spacing: 8) {
                                Text(String(format: "%.1f%%", averageMargin * 100))
                                    .font(AppTheme.serifFont(size: 24, weight: .bold))
                                    .foregroundColor(AppTheme.foreground)
                                Text(loc.t("analytics.revenue.avg_margin"))
                                    .font(AppTheme.sansFont(size: 12))
                                    .foregroundColor(AppTheme.mutedText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .glassmorphic()
                        }
                        
                        // Recent Revenue Chart
                        VStack(alignment: .leading, spacing: 16) {
                            Text(loc.t("analytics.revenue.trend"))
                                .font(AppTheme.serifFont(size: 20, weight: .bold))
                                .foregroundColor(AppTheme.foreground)
                            
                            Chart(recentDesigns.reversed()) { design in
                                BarMark(
                                    x: .value("Date", formatDate(design.createdAt)),
                                    y: .value("Revenue", design.totalCost + design.profit)
                                )
                                .foregroundStyle(AppTheme.secondary)
                                .cornerRadius(4)
                            }
                            .frame(height: 200)
                        }
                        .padding(20)
                        .glassmorphic()
                        
                        // Top Profitable
                        VStack(alignment: .leading, spacing: 16) {
                            Text(loc.t("analytics.revenue.top3"))
                                .font(AppTheme.serifFont(size: 20, weight: .bold))
                                .foregroundColor(AppTheme.foreground)
                            
                            if topProfitable.isEmpty {
                                Text(loc.t("analytics.revenue.no_data"))
                                    .font(AppTheme.sansFont(size: 14))
                                    .foregroundColor(AppTheme.mutedText)
                            } else {
                                ForEach(topProfitable) { design in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(design.title)
                                                .font(AppTheme.sansFont(size: 16, weight: .medium))
                                                .foregroundColor(AppTheme.foreground)
                                            Text(String(format: "%.0f%% Margin", design.profitMargin * 100))
                                                .font(AppTheme.sansFont(size: 12))
                                                .foregroundColor(AppTheme.success)
                                        }
                                        Spacer()
                                        Text("+¥\(String(format: "%.0f", design.profit))")
                                            .font(AppTheme.sansFont(size: 16, weight: .bold))
                                            .foregroundColor(AppTheme.primary)
                                    }
                                    .padding(.vertical, 8)
                                    
                                    if design.id != topProfitable.last?.id {
                                        Divider().background(Color.white.opacity(0.1))
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .glassmorphic()
                    }
                    .padding()
                }
            }
            .navigationTitle(loc.t("analytics.revenue.title"))
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
    
    private func formatDate(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}
