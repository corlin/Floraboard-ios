//
//  InventoryViews.swift
//  Floreboard
//
//  Created by AI Assistant.
//

import SwiftUI

struct InventoryView: View {
  @StateObject private var viewModel = InventoryViewModel()
  @State private var showingAddSheet = false
  @State private var editingFlower: FlowerType? = nil

  var body: some View {
    NavigationView {
      ZStack {
        AppTheme.premiumGradient.ignoresSafeArea()

        ScrollView {
          VStack(spacing: 16) {
            WorkbenchSearchField(
              placeholder: Tx.t("general.search") + "...",
              text: $viewModel.searchText
            )
            .padding(.horizontal)

            LazyVStack(spacing: 16) {
              if viewModel.filteredFlowers.isEmpty {
                VStack(spacing: 14) {
                  Image(systemName: viewModel.flowers.isEmpty ? "leaf.circle" : "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(AppTheme.primary.opacity(0.32))

                  Text(
                    viewModel.flowers.isEmpty
                      ? Tx.t("inventory.list.empty.title")
                      : Tx.t("inventory.search.empty")
                  )
                  .font(AppTheme.serifFont(size: 20, weight: .bold))
                  .foregroundColor(AppTheme.foreground)

                  Text(
                    viewModel.flowers.isEmpty
                      ? Tx.t("inventory.list.empty.desc")
                      : Tx.t("inventory.search.empty.desc")
                  )
                  .font(AppTheme.sansFont(size: 14))
                  .foregroundColor(AppTheme.mutedText)
                  .multilineTextAlignment(.center)

                  if viewModel.flowers.isEmpty {
                    Button {
                      HapticManager.shared.impact(style: .medium)
                      showingAddSheet = true
                    } label: {
                      Label(Tx.t("inventory.add"), systemImage: "plus")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 4)
                  } else if !viewModel.searchText.isEmpty {
                    Button {
                      HapticManager.shared.impact(style: .light)
                      viewModel.searchText = ""
                    } label: {
                      Label(Tx.t("inventory.search.clear"), systemImage: "xmark.circle")
                        .font(AppTheme.sansFont(size: 14, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(AppTheme.primary)
                    .padding(.top, 4)
                  }
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .padding(.top, 24)
                .glassmorphic()
              } else {
                ForEach(viewModel.filteredFlowers) { flower in
                  FlowerRow(
                    flower: flower,
                    onEdit: {
                      HapticManager.shared.impact(style: .light)
                      editingFlower = flower
                    },
                    onDelete: {
                      HapticManager.shared.notification(type: .warning)
                      viewModel.delete(flower)
                    })
                }
              }
            }
            .padding(.horizontal)
            .padding(.bottom, 96)
          }
          .padding(.top)
        }
      }
      .scrollDismissesKeyboard(.interactively)
      .navigationTitle(Tx.t("inventory.title"))
      .overlay {
        WorkbenchBottomActionBar(
          title: Tx.t("inventory.add"),
          systemImage: "plus"
        ) {
          HapticManager.shared.impact(style: .medium)
          showingAddSheet = true
        }
      }
      // Add Sheet
      .sheet(isPresented: $showingAddSheet) {
        EditFlowerSheet(viewModel: viewModel, flowerToEdit: nil)
      }
      // Edit Sheet
      .sheet(item: $editingFlower) { flower in
        EditFlowerSheet(viewModel: viewModel, flowerToEdit: flower)
      }
    }
  }
}

struct FlowerRow: View {
  let flower: FlowerType
  var onEdit: () -> Void
  var onDelete: () -> Void

  // Computed Margin
  var marginPercent: Int {
    guard flower.retailPrice > 0 else { return 0 }
    return Int(((flower.retailPrice - flower.unitCost) / flower.retailPrice) * 100)
  }

  var marginColor: Color {
    if marginPercent >= 60 {
      return AppTheme.success
    } else if marginPercent >= 40 {
      return AppTheme.stockRisk
    } else {
      return AppTheme.danger
    }
  }

  var body: some View {
    HStack(spacing: 16) {
      // Color Circle with Low Stock Indicator
      ZStack {
        Circle()
          .fill(Color(string: flower.color))
          .frame(width: 48, height: 48)
          .overlay(Circle().stroke(AppTheme.hairline, lineWidth: 2))
          .shadow(radius: 2)

        if flower.quantity < 10 {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(AppTheme.danger)
            .background(Circle().fill(AppTheme.surfaceStrong))
            .offset(x: 16, y: -16)
        }
      }

      VStack(alignment: .leading, spacing: 6) {
        HStack {
          Text(flower.name)
            .font(AppTheme.serifFont(size: 18, weight: .semibold))
            .foregroundColor(AppTheme.foreground)

          // Category Badge
          Text(flower.category.displayName)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(AppTheme.primary.opacity(0.1))
            .foregroundColor(AppTheme.primary)
            .cornerRadius(4)
        }

        // Stats Row
        HStack(spacing: 12) {
          Text("\(Tx.t("inventory.row.stock")): \(flower.quantity)")
            .font(AppTheme.sansFont(size: 12))
            .foregroundColor(flower.quantity < 10 ? AppTheme.danger : AppTheme.mutedText)

          Text("\(Tx.t("inventory.row.used")): \(flower.totalUsed ?? 0)")
            .font(AppTheme.sansFont(size: 12))
            .foregroundColor(AppTheme.operationalInfo)
        }

        // Tags
        if let tags = flower.cultureTags, !tags.isEmpty {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack {
              ForEach(tags, id: \.self) { tag in
                Text(Tx.t("inventory.form.cultureOptions.\(tag.lowercased())"))
                  .font(.caption2)
                  .padding(.horizontal, 4)
                  .padding(.vertical, 2)
                  .overlay(
                    RoundedRectangle(cornerRadius: 4).stroke(
                      AppTheme.hairline, lineWidth: 1)
                  )
                  .foregroundColor(AppTheme.mutedText)
              }
            }
          }
        }
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 4) {
        // Price & Cost
        HStack(spacing: 4) {
          Text("¥\(Int(flower.retailPrice))")
            .font(AppTheme.sansFont(size: 16, weight: .bold))
            .foregroundColor(AppTheme.primary)
          Text("(¥\(Int(flower.unitCost)))")
            .font(AppTheme.sansFont(size: 12))
            .foregroundColor(AppTheme.mutedText)
        }

        // Margin
        Text("\(Tx.t("inventory.row.margin")): \(marginPercent)%")
          .font(.caption.bold())
          .foregroundColor(marginColor)

        HStack {
          Button(action: onEdit) {
            Image(systemName: "pencil.circle.fill")
              .foregroundColor(AppTheme.foreground.opacity(0.6))
              .font(.title2)
          }

          Button(action: onDelete) {
            Image(systemName: "trash.circle.fill")
              .foregroundColor(AppTheme.danger.opacity(0.7))
              .font(.title2)
          }
        }
        .padding(.top, 4)
      }
    }
    .padding()
    .glassmorphic()
  }
}

extension Color {
  // Helper to convert string color to Color
  init(string: String) {
    let normalized = string.trimmingCharacters(in: .whitespacesAndNewlines)

    if normalized.hasPrefix("#") {
      let hex = String(normalized.dropFirst())
      var value: UInt64 = 0

      if Scanner(string: hex).scanHexInt64(&value) {
        switch hex.count {
        case 6:
          let red = Double((value & 0xFF0000) >> 16) / 255
          let green = Double((value & 0x00FF00) >> 8) / 255
          let blue = Double(value & 0x0000FF) / 255
          self = Color(red: red, green: green, blue: blue)
          return
        case 8:
          let alpha = Double((value & 0xFF000000) >> 24) / 255
          let red = Double((value & 0x00FF0000) >> 16) / 255
          let green = Double((value & 0x0000FF00) >> 8) / 255
          let blue = Double(value & 0x000000FF) / 255
          self = Color(red: red, green: green, blue: blue, opacity: alpha)
          return
        default:
          break
        }
      }
    }

    switch normalized.lowercased() {
    case "red": self = .red
    case "white": self = .white
    case "pink": self = .pink
    case "yellow": self = .yellow
    case "blue": self = .blue
    case "green": self = .green
    case "purple": self = .purple
    case "orange": self = .orange
    default: self = .gray
    }
  }
}

struct EditFlowerSheet: View {
  @ObservedObject var viewModel: InventoryViewModel
  var flowerToEdit: FlowerType?
  @Environment(\.presentationMode) var presentationMode

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
    NavigationView {
      Form {
        Section(header: Text(Tx.t("inventory.section.details"))) {
          TextField(Tx.t("inventory.form.name"), text: $name)
          TextField(Tx.t("inventory.form.meaning"), text: $meaning)

          Picker(Tx.t("inventory.form.category"), selection: $category) {
            ForEach(FlowerCategory.allCases) { cat in
              Text(cat.displayName).tag(cat)
            }
          }
          Picker(Tx.t("inventory.form.color"), selection: $color) {
            ForEach(colors, id: \.self) { c in
              Text(colorName(c)).tag(c)
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
            Text("\(Tx.t("inventory.form.cost")) (¥)")
            Spacer()
            TextField("0.0", value: $cost, format: .number)
              .keyboardType(.decimalPad)
              .multilineTextAlignment(.trailing)
          }

          HStack {
            Text("\(Tx.t("inventory.form.retail")) (¥)")
            Spacer()
            TextField("0.0", value: $price, format: .number)
              .keyboardType(.decimalPad)
              .multilineTextAlignment(.trailing)
          }
        }
      }

      .navigationTitle(isEditing ? Tx.t("inventory.edit") : Tx.t("inventory.add"))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(Tx.t("general.cancel")) {
            presentationMode.wrappedValue.dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(Tx.t("general.save")) {
            HapticManager.shared.notification(type: .success)
            save()
            presentationMode.wrappedValue.dismiss()
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
