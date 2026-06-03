//
//  FloreboardApp.swift
//  Floreboard
//
//  Created by 陈永林 on 26/01/2026.
//

import SwiftData
import SwiftUI

@main
struct FloreboardApp: App {
  let container: ModelContainer

  init() {
    let schema = Schema([FlowerRecord.self, DesignRecord.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: false)
    do {
      container = try ModelContainer(for: schema, configurations: config)
    } catch {
      fatalError("Failed to initialize ModelContainer: \(error)")
    }
    let context = ModelContext(container)
    InventoryService.shared.configure(with: context)
    HistoryService.shared.configure(with: context)
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .modelContainer(container)
        .environmentObject(AuthService.shared)
        .environmentObject(InventoryService.shared)
    }
  }
}
