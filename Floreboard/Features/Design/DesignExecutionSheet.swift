import SwiftUI

struct ExecutionItem: Identifiable {
  let id = UUID()
  let originalItem: DesignFlowerItem
  var mappedFlowerId: String? // nil means Skip
  var mappedAmount: Int
}

struct DesignExecutionSheet: View {
  let design: DesignResult
  let onExecute: ([InventoryService.DeductionItem]) -> Void
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var inventoryService: InventoryService
  
  @State private var items: [ExecutionItem] = []
  
  var body: some View {
    NavigationStack {
      Form {
        Section(header: Text(Tx.t("design.execution.header"))) {
          Text(Tx.t("design.execution.desc"))
            .font(AppTheme.sansFont(size: 14))
            .foregroundColor(AppTheme.mutedText)
            .padding(.vertical, 4)
        }
        
        ForEach($items) { $item in
          Section {
            VStack(alignment: .leading, spacing: 12) {
              // AI Suggestion
              HStack {
                Text("AI: \(item.originalItem.flowerName)")
                  .font(AppTheme.sansFont(size: 14, weight: .semibold))
                Spacer()
                Text("x\(item.originalItem.count)")
                  .font(AppTheme.sansFont(size: 14, weight: .bold))
                  .foregroundColor(AppTheme.mutedText)
              }
              
              Divider()
              
              // Inventory Mapping
              Picker(Tx.t("design.execution.match"), selection: $item.mappedFlowerId) {
                Text(Tx.t("design.execution.skip")).tag(String?.none)
                ForEach(inventoryService.flowers) { flower in
                  Text("\(flower.name) (Stock: \(flower.quantity))").tag(String?.some(flower.id))
                }
              }
              
              if item.mappedFlowerId != nil {
                Stepper(value: $item.mappedAmount, in: 1...999) {
                  HStack {
                    Text(Tx.t("design.execution.deduct"))
                    Spacer()
                    Text("\(item.mappedAmount)")
                      .font(AppTheme.sansFont(size: 16, weight: .bold))
                      .foregroundColor(AppTheme.primary)
                  }
                }
              }
            }
            .padding(.vertical, 4)
          }
        }
      }
      .navigationTitle(Tx.t("design.action.execute"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(Tx.t("general.cancel")) {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(Tx.t("general.confirm")) {
            let deductions = items.compactMap { item -> InventoryService.DeductionItem? in
              guard let id = item.mappedFlowerId else { return nil }
              return InventoryService.DeductionItem(flowerId: id, amount: item.mappedAmount)
            }
            onExecute(deductions)
            dismiss()
          }
          .font(AppTheme.sansFont(size: 16, weight: .bold))
        }
      }
      .onAppear {
        prepareItems()
      }
    }
  }
  
  private func prepareItems() {
    items = design.flowerList.map { aiItem in
      // Try to fuzzy match
      let match = inventoryService.flowers.first { inventoryFlower in
        inventoryFlower.name.localizedCaseInsensitiveCompare(aiItem.flowerName) == .orderedSame ||
        inventoryFlower.name.localizedCaseInsensitiveContains(aiItem.flowerName) ||
        aiItem.flowerName.localizedCaseInsensitiveContains(inventoryFlower.name)
      }
      
      return ExecutionItem(
        originalItem: aiItem,
        mappedFlowerId: match?.id,
        mappedAmount: aiItem.count
      )
    }
  }
}
