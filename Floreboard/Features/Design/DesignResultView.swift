import SwiftUI

struct ResultView: View {
  let result: DesignResult
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          // Header
          VStack(alignment: .leading, spacing: 8) {
            Text(result.title)
              .font(.title)
              .fontWeight(.bold)
            Text(result.description)
              .font(.body)
              .foregroundColor(AppTheme.mutedText)
          }
          .padding()

          // Flower BOM
          GroupBox(label: Label(Tx.t("result.bom.title"), systemImage: "list.bullet")) {
            VStack(alignment: .leading, spacing: 8) {
              ForEach(result.flowerList) { item in
                HStack {
                  Text(item.flowerName)
                  Spacer()
                  Text("x\(item.count)")
                    .fontWeight(.bold)
                }
                Divider()
              }
              HStack {
                Text(Tx.t("result.cost.title"))
                  .fontWeight(.bold)
                Spacer()
                Text(CurrencyFormat.compact(result.totalCost))
                  .fontWeight(.bold)
                  .foregroundColor(AppTheme.primary)
              }
            }
            .padding(.vertical, 8)
          }
          .padding(.horizontal)

          if let imageError = result.imageError, !imageError.isEmpty {
            GroupBox(label: Label(Tx.t("result.imageError.title"), systemImage: "photo.badge.exclamationmark")) {
              Text(imageError)
                .font(.callout)
                .foregroundColor(AppTheme.mutedText)
                .padding(.vertical, 8)
            }
            .padding(.horizontal)
          }

          // Steps
          GroupBox(label: Label(Tx.t("result.steps.title"), systemImage: "text.book.closed")) {
            VStack(alignment: .leading, spacing: 10) {
              ForEach(Array(result.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top) {
                  Text("\(index + 1).")
                    .foregroundColor(AppTheme.mutedText)
                    .frame(width: 20)
                  Text(step)
                }
              }
            }
            .padding(.vertical, 8)
          }
          .padding(.horizontal)

          // Meaning
          GroupBox(label: Label(Tx.t("result.meaning.title"), systemImage: "heart.text.square")) {
            Text(result.meaningText)
              .italic()
              .padding(.vertical, 8)
          }
          .padding(.horizontal)
        }
      }
      .navigationTitle(Tx.t("result.title"))
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(Tx.t("general.done")) {
            dismiss()
          }
        }
      }
    }
  }
}
