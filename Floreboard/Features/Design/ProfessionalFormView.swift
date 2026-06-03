import SwiftUI

struct ProfessionalFormView: View {
  @ObservedObject var viewModel: DesignViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(Tx.t("app.nav.design") + " (Pro)")
        .font(AppTheme.serifFont(size: 22, weight: .bold))
        .foregroundColor(AppTheme.foreground)

      // Culture Filter
      Picker("Filter", selection: $viewModel.cultureFilter) {
        Text(Tx.t("filter.culture.all")).tag(DesignViewModel.CultureFilter.all)
        Text(Tx.t("filter.culture.japanese")).tag(DesignViewModel.CultureFilter.japanese)
        Text(Tx.t("filter.culture.chinese")).tag(DesignViewModel.CultureFilter.chinese)
        Text(Tx.t("filter.culture.western")).tag(DesignViewModel.CultureFilter.western)
      }
      .pickerStyle(.segmented)

      // School
      HStack {
        Text(Tx.t("design.pro.school.title"))
        Spacer()
        Picker(
          "",
          selection: Binding(
            get: { viewModel.request.school ?? "" },
            set: { viewModel.request.school = $0 })
        ) {
          Text(Tx.t("design.pro.school.select")).tag("")
          ForEach(viewModel.filteredSchools, id: \.self) { id in
            Text(Tx.t("pro.school.\(id).name")).tag(id)
          }
        }.tint(AppTheme.primary)
      }
      Divider()

      // Technique
      HStack {
        Text(Tx.t("design.pro.technique.title"))
        Spacer()
        Picker(
          "",
          selection: Binding(
            get: { viewModel.request.technique ?? "" },
            set: { viewModel.request.technique = $0 })
        ) {
          Text(Tx.t("design.pro.technique.select")).tag("")
          ForEach(viewModel.filteredTechniques, id: \.self) { id in
            Text(Tx.t("pro.tech.\(id).name")).tag(id)
          }
        }.tint(AppTheme.primary)
      }

      Divider()

      // Context Input
      Text(Tx.t("design.pro.context.title"))
        .font(AppTheme.sansFont(size: 14, weight: .medium))
        .foregroundColor(AppTheme.mutedText)

      TextField(
        Tx.t("design.pro.context.placeholder"),
        text: Binding(
          get: { viewModel.request.culturalContext ?? "" },
          set: { viewModel.request.culturalContext = $0 })
      )
      .padding()
      .background(AppTheme.surfaceGlass)
      .cornerRadius(AppTheme.controlRadius)
    }
    .padding()
    .glassmorphic()

    // Pro Mode Additional Fields (Proportion, Season, Budget)
    VStack(alignment: .leading, spacing: 16) {
      // Proportion Rule
      HStack {
        Text(Tx.t("design.pro.proportion.title"))  // Ensure translation key exists or use fallback
        Spacer()
        Picker(
          "Proportion",
          selection: Binding(
            get: { viewModel.request.proportionRule ?? "free" },
            set: { viewModel.request.proportionRule = $0 }
          )
        ) {
          ForEach(PROPORTIONS) { p in
            Text(p.name).tag(p.id)
          }
        }.tint(AppTheme.primary)
      }
      Divider()

      // Seasonality
      HStack {
        Text(Tx.t("design.pro.season.title"))
        Spacer()
        Picker(
          "Season",
          selection: Binding(
            get: { viewModel.request.seasonality ?? "all" },
            set: { viewModel.request.seasonality = $0 }
          )
        ) {
          ForEach(SEASONS) { s in
            Text(s.name).tag(s.id)
          }
        }.tint(AppTheme.primary)
      }
      Divider()

      // Budget (Required for Pro too)
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
