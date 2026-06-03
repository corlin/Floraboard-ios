import SwiftUI

struct HistoryView: View {
  @StateObject private var historyService = HistoryService.shared
  @State private var searchText = ""
  var onStartDesign: (() -> Void)? = nil

  var filteredDesigns: [DesignResult] {
    if searchText.isEmpty {
      return historyService.savedDesigns
    } else {
      return historyService.savedDesigns.filter { design in
        design.title.localizedCaseInsensitiveContains(searchText)
          || design.description.localizedCaseInsensitiveContains(searchText)
          || design.meaningText.localizedCaseInsensitiveContains(searchText)
      }
    }
  }

  var body: some View {
    NavigationStack {
      ZStack {
        AppTheme.premiumGradient.ignoresSafeArea()

        ScrollView {
          VStack(spacing: 20) {
            WorkbenchSearchField(
              placeholder: Tx.t("history.search"),
              text: $searchText
            )
            .padding(.horizontal)

            if filteredDesigns.isEmpty {
              VStack(alignment: .center, spacing: 16) {
                Image(systemName: historyService.savedDesigns.isEmpty ? "sparkles" : "magnifyingglass")
                  .font(.system(size: 60))
                  .foregroundColor(AppTheme.primary.opacity(0.3))

                Text(historyService.savedDesigns.isEmpty ? Tx.t("history.empty") : Tx.t("history.search.empty"))
                  .font(AppTheme.serifFont(size: 20, weight: .bold))
                  .foregroundColor(AppTheme.foreground)

                Text(
                  historyService.savedDesigns.isEmpty
                    ? Tx.t("history.empty.desc")
                    : Tx.t("history.search.empty.desc")
                )
                  .font(AppTheme.sansFont(size: 14))
                  .foregroundColor(AppTheme.mutedText)
                  .multilineTextAlignment(.center)

                if historyService.savedDesigns.isEmpty, let onStartDesign {
                  Button {
                    onStartDesign()
                  } label: {
                    Label(Tx.t("history.empty.action"), systemImage: "sparkles")
                  }
                  .buttonStyle(PrimaryButtonStyle())
                  .padding(.top, 4)
                } else if !searchText.isEmpty {
                  Button {
                    HapticManager.shared.impact(style: .light)
                    searchText = ""
                  } label: {
                    Label(Tx.t("history.search.clear"), systemImage: "xmark.circle")
                      .font(AppTheme.sansFont(size: 14, weight: .semibold))
                  }
                  .buttonStyle(.plain)
                  .foregroundColor(AppTheme.primary)
                  .padding(.top, 4)
                }
              }
              .frame(maxWidth: .infinity)
              .padding(24)
              .padding(.top, 36)
              .glassmorphic()
              .padding(.horizontal)
            } else {
              LazyVStack(spacing: 16) {
                ForEach(filteredDesigns) { design in
                  NavigationLink(destination: DesignDetailView(design: design)) {
                    HistoryRow(design: design)
                  }
                  .buttonStyle(PlainButtonStyle())  // Important for custom rows in ScrollView
                }
              }
              .padding(.horizontal)
              .padding(.bottom, 20)
            }
          }
          .padding(.top)
        }
      }
      .navigationTitle(Tx.t("history.title"))
    }
  }
}
