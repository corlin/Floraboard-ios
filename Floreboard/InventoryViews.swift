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
            // Search Bar
            HStack {
              Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
              TextField(Tx.t("general.search") + "...", text: $viewModel.searchText)
            }
            .padding()
            .background(Color.white.opacity(0.5))
            .cornerRadius(10)
            .padding(.horizontal)

            LazyVStack(spacing: 16) {
              if viewModel.filteredFlowers.isEmpty {
                VStack(spacing: 12) {
                  Image(systemName: "leaf.circle")  // Replaced flower.circle
                    .font(.system(size: 48))
                    .foregroundColor(.secondary.opacity(0.5))
                  Text(Tx.t("inventory.list.empty.title"))
                    .font(AppTheme.sansFont(size: 16))
                    .foregroundColor(.secondary)
                }
                .padding(.top, 40)
              } else {
                ForEach(viewModel.filteredFlowers) { flower in
                  FlowerRow(
                    flower: flower,
                    onEdit: {
                      editingFlower = flower
                    },
                    onDelete: {
                      viewModel.delete(flower)
                    })
                }
              }
            }
            .padding(.horizontal)
            .padding(.bottom, 80)
          }
          .padding(.top)
        }
      }
      .scrollDismissesKeyboard(.interactively)
      .navigationTitle(Tx.t("inventory.title"))
      // Floating Action Button
      .overlay(
        VStack {
          Spacer()
          HStack {
            Spacer()
            Button(action: { showingAddSheet = true }) {
              Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(AppTheme.primary)
                .clipShape(Circle())
                .shadow(color: AppTheme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding()
          }
        }
      )
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
      return .green
    } else if marginPercent >= 40 {
      return .orange
    } else {
      return .red
    }
  }

  var body: some View {
    HStack(spacing: 16) {
      // Color Circle with Low Stock Indicator
      ZStack {
        Circle()
          .fill(Color(string: flower.color))
          .frame(width: 48, height: 48)
          .overlay(Circle().stroke(Color.white, lineWidth: 2))
          .shadow(radius: 2)

        if flower.quantity < 10 {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.red)
            .background(Circle().fill(Color.white))
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
            .foregroundColor(flower.quantity < 10 ? .red : .secondary)

          Text("\(Tx.t("inventory.row.used")): \(flower.totalUsed ?? 0)")
            .font(AppTheme.sansFont(size: 12))
            .foregroundColor(.blue)
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
                      Color.secondary.opacity(0.3), lineWidth: 1)
                  )
                  .foregroundColor(.secondary)
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
            .foregroundColor(.secondary)
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
              .foregroundColor(.red.opacity(0.6))
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
    switch string.lowercased() {
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
              if selectedCultures.contains(culture) {
                selectedCultures.remove(culture)
              } else {
                selectedCultures.insert(culture)
              }
            }) {
              HStack {
                Text(Tx.t("inventory.form.cultureOptions.\(culture)"))
                  .foregroundColor(.primary)
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
            save()
            presentationMode.wrappedValue.dismiss()
          }
          .disabled(name.isEmpty)
        }
      }
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
