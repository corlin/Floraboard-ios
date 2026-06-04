import SwiftUI

struct EditFlowerSheet: View {
  @ObservedObject var viewModel: InventoryViewModel
  var flowerToEdit: FlowerType?
  @Environment(\.dismiss) private var dismiss

  @State private var name = ""
  @State private var color = "White"
  @State private var quantity = 10
  @State private var cost = 5.0
  @State private var price = 15.0
  @State private var category = FlowerCategory.main
  @State private var meaning = ""

  // Culture Tags
  let availableCultures = ["western", "chinese", "japanese", "universal"]
  @State private var selectedCultures: Set<String> = []

  let colors = ["White", "Red", "Pink", "Yellow", "Purple", "Green", "Blue", "Orange"]

  func colorName(_ color: String) -> String {
    return Tx.t("color.\(color.lowercased())")
  }

  var isEditing: Bool { flowerToEdit != nil }

  var body: some View {
    NavigationStack {
      Form {
        Section(header: Text(Tx.t("inventory.section.details"))) {
          TextField(Tx.t("inventory.form.name"), text: $name)
          TextField(Tx.t("inventory.form.meaning"), text: $meaning)

          Picker(Tx.t("inventory.form.category"), selection: $category) {
            ForEach(FlowerCategory.allCases) { cat in
              Text(cat.displayName).tag(cat)
            }
          }
          
          let availableColors = colors.contains(color) ? colors : (colors + [color])
          Picker(Tx.t("inventory.form.color"), selection: $color) {
            ForEach(availableColors, id: \.self) { c in
              if c.hasPrefix("#") {
                Text(c).tag(c)
              } else {
                Text(colorName(c)).tag(c)
              }
            }
          }
        }

        Section(header: Text(Tx.t("inventory.form.culture"))) {
          ForEach(availableCultures, id: \.self) { culture in
            Button(action: {
              HapticManager.shared.selection()
              if selectedCultures.contains(culture) {
                selectedCultures.remove(culture)
              } else {
                selectedCultures.insert(culture)
              }
            }) {
              HStack {
                Text(Tx.t("inventory.form.cultureOptions.\(culture)"))
                  .foregroundColor(AppTheme.foreground)
                Spacer()
                if selectedCultures.contains(culture) {
                  Image(systemName: "checkmark").foregroundColor(AppTheme.primary)
                }
              }
            }
          }
        }

        Section(header: Text(Tx.t("inventory.section.stock"))) {
          Stepper("\(Tx.t("inventory.form.stock")): \(quantity)", value: $quantity, in: 0...1000)

          HStack {
            Text("\(Tx.t("inventory.form.cost")) (\(CurrencyFormat.currencyUnit))")
            Spacer()
            TextField("0.0", value: $cost, format: .number)
              .keyboardType(.decimalPad)
              .multilineTextAlignment(.trailing)
          }

          HStack {
            Text("\(Tx.t("inventory.form.retail")) (\(CurrencyFormat.currencyUnit))")
            Spacer()
            TextField("0.0", value: $price, format: .number)
              .keyboardType(.decimalPad)
              .multilineTextAlignment(.trailing)
          }
        }

        if isEditing {
          Section {
            Button(role: .destructive) {
              HapticManager.shared.notification(type: .warning)
              if let flower = flowerToEdit {
                viewModel.delete(flower)
              }
              dismiss()
            } label: {
              HStack {
                Spacer()
                Text(Tx.t("general.delete"))
                  .font(AppTheme.sansFont(size: 16, weight: .bold))
                Spacer()
              }
            }
          }
        }
      }

      .navigationTitle(isEditing ? Tx.t("inventory.edit") : Tx.t("inventory.add"))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(Tx.t("general.cancel")) {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(Tx.t("general.save")) {
            HapticManager.shared.notification(type: .success)
            save()
            dismiss()
          }
          .disabled(name.isEmpty)
        }
      }
      .keyboardDismissToolbar()
    }
    .onAppear {
      if let flower = flowerToEdit {
        name = flower.name
        color = flower.color
        quantity = flower.quantity
        cost = flower.unitCost
        price = flower.retailPrice
        category = flower.category
        meaning = flower.meaning ?? ""
        selectedCultures = Set(flower.cultureTags ?? [])
      }
    }
  }

  func save() {
    if var flower = flowerToEdit {
      // Update
      flower.name = name
      flower.color = color
      flower.quantity = quantity
      flower.unitCost = cost
      flower.retailPrice = price
      flower.category = category
      flower.meaning = meaning
      flower.cultureTags = Array(selectedCultures)
      // If initializing used defaults? No, preserve existing.
      viewModel.updateFlower(flower)
    } else {
      // Add
      viewModel.addFlower(
        name: name, color: color, quantity: quantity, cost: cost, price: price,
        category: category, cultureTags: Array(selectedCultures), meaning: meaning)
    }
  }
}
