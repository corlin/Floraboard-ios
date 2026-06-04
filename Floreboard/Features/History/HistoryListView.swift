import SwiftUI

struct HistoryView: View {
  @EnvironmentObject var historyService: HistoryService
  @Environment(\.hapticManager) var hapticManager
  @State private var searchText = ""
  @State private var animateItems = false
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
                if historyService.savedDesigns.isEmpty {
                  Image("HistoryEmpty")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                    .shadow(color: AppTheme.shadow, radius: 10, x: 0, y: 5)
                    .padding(.bottom, 10)
                } else {
                  Image(systemName: "magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundStyle(
                      LinearGradient(
                        colors: [AppTheme.creative.opacity(0.7), AppTheme.primary.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                    )
                }

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
                    hapticManager.impact(style: .light)
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
                ForEach(Array(filteredDesigns.enumerated()), id: \.element.id) { index, design in
                  NavigationLink(destination: DesignDetailView(design: design)) {
                    HistoryRow(design: design)
                  }
                  .buttonStyle(PlainButtonStyle())  // Important for custom rows in ScrollView
                  .opacity(animateItems ? 1 : 0)
                  .offset(y: animateItems ? 0 : 20)
                  .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(min(index, 15)) * 0.05), value: animateItems)
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
      .onAppear {
        animateItems = true
      }
    }
  }
}
