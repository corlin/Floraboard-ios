import SwiftUI

struct ProfessionalFormView: View {
  @ObservedObject var viewModel: DesignViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text(Tx.t("app.nav.design") + " (Pro)")
        .font(AppTheme.serifFont(size: 22, weight: .bold))
        .foregroundColor(AppTheme.foreground)

      // Culture Filter
      FlowChipSelector(
        options: [
            (DesignViewModel.CultureFilter.all, Tx.t("filter.culture.all")),
            (DesignViewModel.CultureFilter.japanese, Tx.t("filter.culture.japanese")),
            (DesignViewModel.CultureFilter.chinese, Tx.t("filter.culture.chinese")),
            (DesignViewModel.CultureFilter.western, Tx.t("filter.culture.western"))
        ],
        selection: $viewModel.cultureFilter
      )

      Divider()

      // School
      VStack(alignment: .leading, spacing: 12) {
        Label(Tx.t("design.pro.school.title"), systemImage: "building.columns")
            .font(AppTheme.serifFont(size: 18, weight: .semibold))
            .foregroundColor(AppTheme.foreground)
        
        let schoolOptions: [(String, String)] = [("", Tx.t("design.pro.school.select"))] + viewModel.filteredSchools.map { ($0, Tx.t("pro.school.\($0).name")) }
        
        FlowChipSelector(
          options: schoolOptions,
          selection: Binding(
            get: { viewModel.request.school ?? "" },
            set: { viewModel.request.school = $0 }
          ),
          activeColor: AppTheme.secondary
        )
      }

      Divider()

      // Technique
      VStack(alignment: .leading, spacing: 12) {
        Label(Tx.t("design.pro.technique.title"), systemImage: "scissors")
            .font(AppTheme.serifFont(size: 18, weight: .semibold))
            .foregroundColor(AppTheme.foreground)
            
        let techOptions: [(String, String)] = [("", Tx.t("design.pro.technique.select"))] + viewModel.filteredTechniques.map { ($0, Tx.t("pro.tech.\($0).name")) }
        
        FlowChipSelector(
          options: techOptions,
          selection: Binding(
            get: { viewModel.request.technique ?? "" },
            set: { viewModel.request.technique = $0 }
          ),
          activeColor: AppTheme.secondary
        )
      }

      Divider()

      // Context Input
      VStack(alignment: .leading, spacing: 8) {
          Label(Tx.t("design.pro.context.title"), systemImage: "text.quote")
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
          .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius))
          .overlay(
            RoundedRectangle(cornerRadius: AppTheme.controlRadius)
              .stroke(AppTheme.hairline, lineWidth: 1)
          )
      }
      
      Divider()

      // Proportion Rule
      VStack(alignment: .leading, spacing: 12) {
        Label(Tx.t("design.pro.proportion.title"), systemImage: "ruler")
            .font(AppTheme.serifFont(size: 18, weight: .semibold))
            .foregroundColor(AppTheme.foreground)
            
        FlowChipSelector(
          options: PROPORTIONS.map { ($0.id, $0.name) },
          selection: Binding(
            get: { viewModel.request.proportionRule ?? "free" },
            set: { viewModel.request.proportionRule = $0 }
          ),
          activeColor: AppTheme.creative
        )
      }

      Divider()

      // Seasonality
      VStack(alignment: .leading, spacing: 12) {
        Label(Tx.t("design.pro.season.title"), systemImage: "leaf")
            .font(AppTheme.serifFont(size: 18, weight: .semibold))
            .foregroundColor(AppTheme.foreground)
            
        FlowChipSelector(
          options: SEASONS.map { ($0.id, $0.name) },
          selection: Binding(
            get: { viewModel.request.seasonality ?? "all" },
            set: { viewModel.request.seasonality = $0 }
          ),
          activeColor: AppTheme.creative
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
