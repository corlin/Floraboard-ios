//
//  DesignModels.swift
//  Floreboard
//
//  Created by AI Assistant.
//

import Foundation

// MARK: - Constants & Enums for Professional Mode

struct FloralSchool: Identifiable, Hashable {
  let id: String
  let culture: CultureType
  let _descKey: String

  var name: String { Tx.t("pro.school.\(id).name") }
  // desc skipped for brevity or added later if needed
}

enum CultureType: String {
  case japanese, chinese, western

  var icon: String {
    switch self {
    case .japanese: return "🎴"
    case .chinese: return "🏮"
    case .western: return "🌹"
    }
  }
}

struct FloralTechnique: Identifiable, Hashable {
  let id: String
  let cultures: [CultureType]
  var name: String { Tx.t("pro.tech.\(id).name") }
}

struct ProportionRule: Identifiable, Hashable {
  let id: String
  let cultures: [CultureType]
  var name: String { Tx.t("pro.prop.\(id).name") }
}

struct FloralSeason: Identifiable, Hashable {
  let id: String
  let cultures: [CultureType]
  var name: String { Tx.t("pro.season.\(id).name") }
}

// Data Sources

let SCHOOLS: [FloralSchool] = [
  FloralSchool(id: "japanese_ikenobo", culture: .japanese, _descKey: ""),
  FloralSchool(id: "japanese_ohara", culture: .japanese, _descKey: ""),
  FloralSchool(id: "japanese_sogetsu", culture: .japanese, _descKey: ""),
  FloralSchool(id: "chinese_literati", culture: .chinese, _descKey: ""),
  FloralSchool(id: "chinese_zen", culture: .chinese, _descKey: ""),
  FloralSchool(id: "western_biedermeier", culture: .western, _descKey: ""),
  FloralSchool(id: "western_english", culture: .western, _descKey: ""),
  FloralSchool(id: "fusion", culture: .western, _descKey: ""),
]

let TECHNIQUES: [FloralTechnique] = [
  FloralTechnique(id: "kenzan", cultures: [.japanese]),
  FloralTechnique(id: "spiral_hand_tied", cultures: [.western]),
  FloralTechnique(id: "parallel", cultures: [.western, .japanese]),
  FloralTechnique(id: "pave", cultures: [.western]),
  FloralTechnique(id: "cascade", cultures: [.western, .chinese]),
  FloralTechnique(id: "oasis", cultures: [.western, .chinese, .japanese]),
  FloralTechnique(id: "wiring", cultures: [.western]),
]

let PROPORTIONS: [ProportionRule] = [
  ProportionRule(id: "7_5_3", cultures: [.japanese]),
  ProportionRule(id: "golden_ratio", cultures: [.western]),
  ProportionRule(id: "free", cultures: [.japanese, .chinese, .western]),
]

let SEASONS: [FloralSeason] = [
  FloralSeason(id: "spring", cultures: [.japanese, .chinese, .western]),
  FloralSeason(id: "summer", cultures: [.japanese, .chinese, .western]),
  FloralSeason(id: "autumn", cultures: [.japanese, .chinese, .western]),
  FloralSeason(id: "winter", cultures: [.japanese, .chinese, .western]),
  FloralSeason(id: "all", cultures: [.japanese, .chinese, .western]),
]
