import SwiftUI

struct QuickFormView: View {
  @ObservedObject var viewModel: DesignViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(Tx.t("design.step.scene"))
        .font(AppTheme.serifFont(size: 22, weight: .bold))
        .foregroundColor(AppTheme.foreground)

      HStack {
        Text(Tx.t("design.step.scene"))
        Spacer()
        Picker("", selection: $viewModel.request.occasion) {
          ForEach(OccasionType.allCases) { type in Text(type.displayName).tag(type) }
        }.pickerStyle(.menu).tint(AppTheme.primary)
      }
      Divider()
      HStack {
        Text(Tx.t("design.style.title"))
        Spacer()
        Picker("", selection: $viewModel.request.style) {
          ForEach(StyleType.allCases) { type in Text(type.displayName).tag(type) }
        }.pickerStyle(.menu).tint(AppTheme.primary)
      }
      Divider()
      HStack {
        Text(Tx.t("design.budget.title"))
        Spacer()
        TextField("500", value: $viewModel.request.budget, format: .number)
          .keyboardType(.decimalPad)
          .multilineTextAlignment(.trailing)
          .foregroundColor(AppTheme.primary)
          .font(.system(size: 18, weight: .bold))
      }
    }
    .padding()
    .glassmorphic()
  }
}
