import SwiftUI

struct QuickFormView: View {
  @ObservedObject var viewModel: DesignViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      
      // Occasion
      VStack(alignment: .leading, spacing: 12) {
        Label(Tx.t("design.step.scene"), systemImage: "gift")
          .font(AppTheme.serifFont(size: 22, weight: .bold))
          .foregroundColor(AppTheme.foreground)

        FlowChipSelector(
          options: OccasionType.allCases.map { ($0, $0.displayName) },
          selection: $viewModel.request.occasion
        )
      }

      Divider()

      // Style
      VStack(alignment: .leading, spacing: 12) {
        Label(Tx.t("design.style.title"), systemImage: "paintpalette")
          .font(AppTheme.serifFont(size: 18, weight: .semibold))
          .foregroundColor(AppTheme.foreground)

        FlowChipSelector(
          options: StyleType.allCases.map { ($0, $0.displayName) },
          selection: $viewModel.request.style,
          activeColor: AppTheme.secondary
        )
      }

      Divider()

      // Budget
      VStack(alignment: .leading, spacing: 8) {
        Label(Tx.t("design.budget.title"), systemImage: "banknote")
          .font(AppTheme.serifFont(size: 18, weight: .semibold))
          .foregroundColor(AppTheme.foreground)

        HStack(alignment: .firstTextBaseline, spacing: 4) {
          Text(CurrencyFormat.currencyUnit)
            .font(AppTheme.sansFont(size: 24, weight: .semibold))
            .foregroundColor(AppTheme.mutedText)
          
          TextField("500", value: $viewModel.request.budget, format: .number)
            .keyboardType(.decimalPad)
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(AppTheme.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surfaceGlass)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.controlRadius)
                .stroke(AppTheme.hairline, lineWidth: 1)
        )
      }
    }
  }
}
