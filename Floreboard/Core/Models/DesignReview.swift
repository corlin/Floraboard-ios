//
//  DesignReview.swift
//  Floreboard
//
//  专业校验结果与生成参数快照。与网页端、云端 `designs.findings` / `designs.request` 同构：
//  校验由服务端的确定性规则计算（免费、不依赖 AI），这里只负责保存与展示。
//

import Foundation

/// 一条校验发现：规则 id + 参数 + 级别，文案由客户端按界面语言渲染。
struct DesignFinding: Codable, Equatable, Identifiable {
  enum Level: String, Codable { case error, warn, info }

  var id: String
  var level: Level
  var params: [String: String]
  var flowers: [String]? = nil

  enum CodingKeys: String, CodingKey { case id, level, params, flowers }

  init(id: String, level: Level, params: [String: String] = [:], flowers: [String]? = nil) {
    self.id = id
    self.level = level
    self.params = params
    self.flowers = flowers
  }

  /// 参数里数字与字符串都可能出现（如 n: 4、name: "玫瑰"），统一成字符串
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decode(String.self, forKey: .id)
    level = (try? c.decode(Level.self, forKey: .level)) ?? .info
    flowers = try? c.decodeIfPresent([String].self, forKey: .flowers)
    var out: [String: String] = [:]
    if let raw = try? c.decodeIfPresent([String: FlexibleScalar].self, forKey: .params) {
      for (k, v) in raw { out[k] = v.text }
    }
    params = out
  }
}

/// 同一个 id 在列表里只出现一次即可（SwiftUI ForEach 用），规则 id 本身在一份方案内唯一。
private struct FlexibleScalar: Decodable {
  let text: String
  init(from decoder: Decoder) throws {
    let c = try decoder.singleValueContainer()
    if let s = try? c.decode(String.self) { text = s }
    else if let i = try? c.decode(Int.self) { text = String(i) }
    else if let d = try? c.decode(Double.self) {
      text = d == d.rounded() ? String(Int(d)) : String(d)
    } else if let b = try? c.decode(Bool.self) { text = String(b) }
    else { text = "" }
  }
}

struct DesignFindings: Codable, Equatable {
  /// 规则库版本；"plan" 表示来自生成接口、尚未被云端重算
  var v: String
  var at: String
  var items: [DesignFinding]

  var errorCount: Int { items.filter { $0.level == .error }.count }
  var warnCount: Int { items.filter { $0.level == .warn }.count }
  var infoCount: Int { items.count - errorCount - warnCount }
  /// 历史列表徽标：只统计严重问题与建议，纯提示不打扰
  var badgeCount: Int { errorCount + warnCount }
}

/// 生成参数快照：服务端据此做流派/场合/季节相关校验，并用于规则效果统计。
struct DesignRequestSnapshot: Codable, Equatable {
  var occasion: String?
  var recipient: String?
  var style: String?
  var budget: Double?
  var school: String?
  var technique: String?
  var seasonality: String?
  var language: String?

  init(_ request: DesignRequest, language: String) {
    occasion = request.occasion.rawValue
    recipient = request.recipient.rawValue
    style = request.style.rawValue
    budget = request.budget
    school = request.school
    technique = request.technique
    seasonality = request.seasonality
    self.language = language
  }
}
