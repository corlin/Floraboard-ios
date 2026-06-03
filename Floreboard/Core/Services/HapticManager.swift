//
//  HapticManager.swift
//  Floreboard
//
//  Created by AI Assistant.
//

import UIKit

class HapticManager {
  static let shared = HapticManager()

  private let selectionGenerator = UISelectionFeedbackGenerator()
  private let notificationGenerator = UINotificationFeedbackGenerator()
  private let impactLight = UIImpactFeedbackGenerator(style: .light)
  private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
  private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)

  private init() {}

  func selection() {
    selectionGenerator.selectionChanged()
    selectionGenerator.prepare()
  }

  func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
    notificationGenerator.notificationOccurred(type)
    notificationGenerator.prepare()
  }

  func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
    switch style {
    case .light:
      impactLight.impactOccurred()
      impactLight.prepare()
    case .medium:
      impactMedium.impactOccurred()
      impactMedium.prepare()
    case .heavy:
      impactHeavy.impactOccurred()
      impactHeavy.prepare()
    default:
      impactLight.impactOccurred()
    }
  }
}
