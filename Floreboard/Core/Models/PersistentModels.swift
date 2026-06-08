//
//  PersistentModels.swift
//  Floreboard
//
//  SwiftData models for persistent storage.
//

import Foundation
import SwiftData

@Model
final class FlowerRecord {
  @Attribute(.unique) var id: String
  var tenantId: String?
  var name: String
  var color: String
  var quantity: Int
  var initialStock: Int
  var categoryRaw: String
  var unitCost: Double
  var retailPrice: Double
  var meaning: String?
  var totalUsed: Int?
  var cultureTags: [String]
  var createdAt: Double?
  var updatedAt: Double?
  var syncId: String?
  var syncVersion: Int?
  var syncedAt: Double?

  init(from flower: FlowerType) {
    self.id = flower.id
    self.name = flower.name
    self.color = flower.color
    self.quantity = flower.quantity
    self.initialStock = flower.initialStock
    self.categoryRaw = flower.category.rawValue
    self.unitCost = flower.unitCost
    self.retailPrice = flower.retailPrice
    self.meaning = flower.meaning
    self.totalUsed = flower.totalUsed
    self.cultureTags = flower.cultureTags ?? []
    self.createdAt = flower.createdAt
    self.updatedAt = flower.updatedAt
    self.syncId = flower.syncId
    self.syncVersion = flower.syncVersion
    self.syncedAt = flower.syncedAt
  }

  func toFlowerType() -> FlowerType {
    var flower = FlowerType(
      id: id,
      name: name,
      color: color,
      quantity: quantity,
      initialStock: initialStock,
      category: FlowerCategory(rawValue: categoryRaw) ?? .main,
      unitCost: unitCost,
      retailPrice: retailPrice,
      meaning: meaning
    )
    flower.totalUsed = totalUsed
    flower.cultureTags = cultureTags.isEmpty ? nil : cultureTags
    flower.createdAt = createdAt
    flower.updatedAt = updatedAt
    flower.syncId = syncId
    flower.syncVersion = syncVersion
    flower.syncedAt = syncedAt
    return flower
  }

  /// Update this record in-place from a FlowerType struct.
  func update(from flower: FlowerType) {
    name = flower.name
    color = flower.color
    quantity = flower.quantity
    initialStock = flower.initialStock
    categoryRaw = flower.category.rawValue
    unitCost = flower.unitCost
    retailPrice = flower.retailPrice
    meaning = flower.meaning
    totalUsed = flower.totalUsed
    cultureTags = flower.cultureTags ?? []
    createdAt = flower.createdAt
    updatedAt = flower.updatedAt
    syncId = flower.syncId
    syncVersion = flower.syncVersion
    syncedAt = flower.syncedAt
  }
}

@Model
final class DesignRecord {
  @Attribute(.unique) var id: String
  var tenantId: String?
  var requestId: String
  var title: String
  var designDescription: String
  var flowerListData: Data
  var reasoning: String?
  var stepsData: Data
  var imageUrl: String?
  var imageTaskId: String?
  var imageStatusRaw: String?
  var imageError: String?
  var imagePrompt: String?
  var meaningText: String
  var totalCost: Double
  var profit: Double
  var profitMargin: Double
  var createdAt: Double
  var requirements: String?
  var rating: Int?
  var feedback: String?
  var statusRaw: String
  var executedAt: Double?
  var syncId: String?
  var syncVersion: Int?
  var syncedAt: Double?

  init(from design: DesignResult) {
    self.id = design.id
    self.requestId = design.requestId
    self.title = design.title
    self.designDescription = design.description
    self.flowerListData = (try? JSONEncoder().encode(design.flowerList)) ?? Data()
    self.reasoning = design.reasoning
    self.stepsData = (try? JSONEncoder().encode(design.steps)) ?? Data()
    self.imageUrl = design.imageUrl
    self.imageTaskId = design.imageTaskId
    self.imageStatusRaw = design.imageStatus?.rawValue
    self.imageError = design.imageError
    self.imagePrompt = design.imagePrompt
    self.meaningText = design.meaningText
    self.totalCost = design.totalCost
    self.profit = design.profit
    self.profitMargin = design.profitMargin
    self.createdAt = design.createdAt
    self.requirements = design.requirements
    self.rating = design.rating
    self.feedback = design.feedback
    self.statusRaw = design.status.rawValue
    self.executedAt = design.executedAt
    self.syncId = design.syncId
    self.syncVersion = design.syncVersion
    self.syncedAt = design.syncedAt
  }

  func toDesignResult() -> DesignResult {
    let flowerList = (try? JSONDecoder().decode([DesignFlowerItem].self, from: flowerListData)) ?? []
    let steps = (try? JSONDecoder().decode([String].self, from: stepsData)) ?? []

    var result = DesignResult(
      id: id,
      requestId: requestId,
      title: title,
      description: designDescription,
      flowerList: flowerList,
      steps: steps,
      meaningText: meaningText,
      totalCost: totalCost,
      profit: profit,
      profitMargin: profitMargin,
      createdAt: createdAt,
      status: DesignStatus(rawValue: statusRaw) ?? .draft
    )
    result.reasoning = reasoning
    result.imageUrl = imageUrl
    result.imageTaskId = imageTaskId
    result.imageStatus = imageStatusRaw.flatMap { ImageStatus(rawValue: $0) }
    result.imageError = imageError
    result.imagePrompt = imagePrompt
    result.requirements = requirements
    result.rating = rating
    result.feedback = feedback
    result.executedAt = executedAt
    result.syncId = syncId
    result.syncVersion = syncVersion
    result.syncedAt = syncedAt
    return result
  }

  /// Update this record in-place from a DesignResult struct.
  func update(from design: DesignResult) {
    requestId = design.requestId
    title = design.title
    designDescription = design.description
    flowerListData = (try? JSONEncoder().encode(design.flowerList)) ?? Data()
    reasoning = design.reasoning
    stepsData = (try? JSONEncoder().encode(design.steps)) ?? Data()
    imageUrl = design.imageUrl
    imageTaskId = design.imageTaskId
    imageStatusRaw = design.imageStatus?.rawValue
    imageError = design.imageError
    imagePrompt = design.imagePrompt
    meaningText = design.meaningText
    totalCost = design.totalCost
    profit = design.profit
    profitMargin = design.profitMargin
    createdAt = design.createdAt
    requirements = design.requirements
    rating = design.rating
    feedback = design.feedback
    statusRaw = design.status.rawValue
    executedAt = design.executedAt
    syncId = design.syncId
    syncVersion = design.syncVersion
    syncedAt = design.syncedAt
  }
}
