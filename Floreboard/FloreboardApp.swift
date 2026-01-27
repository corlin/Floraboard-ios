//
//  FloreboardApp.swift
//  Floreboard
//
//  Created by 陈永林 on 26/01/2026.
//

import SwiftUI

@main
struct FloreboardApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(AuthService.shared)
        .environmentObject(InventoryService.shared)
    }
  }
}
