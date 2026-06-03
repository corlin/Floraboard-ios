//
//  InitialInventory.swift
//  Floreboard
//
//  Created by AI Assistant.
//

import Foundation

extension FlowerType {
  static var initialData: [FlowerType] {
    return [
      // 现代通用花材 (Universal/Western)
      FlowerType(
        name: "白玫瑰", color: "#FFFFFF", quantity: 50, initialStock: 50, category: .main, unitCost: 5,
        retailPrice: 12, meaning: "纯洁的爱"
      ).withTags(["western", "universal"]),
      FlowerType(
        name: "粉玫瑰", color: "#FFC0CB", quantity: 30, initialStock: 30, category: .main, unitCost: 5,
        retailPrice: 15, meaning: "初恋、感动"
      ).withTags(["western", "universal"]),
      FlowerType(
        name: "向日葵", color: "#FFD700", quantity: 20, initialStock: 20, category: .main, unitCost: 6,
        retailPrice: 10, meaning: "沉默的爱、忠诚"
      ).withTags(["western", "universal"]),
      FlowerType(
        name: "尤加利叶", color: "#5F8575", quantity: 100, initialStock: 100, category: .foliage,
        unitCost: 2, retailPrice: 5, meaning: "恩赐"
      ).withTags(["western", "universal"]),
      FlowerType(
        name: "洋甘菊", color: "#FFFFE0", quantity: 60, initialStock: 60, category: .filler,
        unitCost: 3, retailPrice: 8, meaning: "逆境中的坚强"
      ).withTags(["western", "universal"]),
      FlowerType(
        name: "蓝色绣球", color: "#87CEEB", quantity: 15, initialStock: 15, category: .main,
        unitCost: 15, retailPrice: 38, meaning: "圆满、团聚"
      ).withTags(["western", "universal"]),
      FlowerType(
        name: "百合", color: "#FFFFFF", quantity: 20, initialStock: 20, category: .main, unitCost: 8,
        retailPrice: 20, meaning: "百年好合"
      ).withTags(["chinese", "western", "universal"]),
      FlowerType(
        name: "郁金香", color: "#FFA500", quantity: 25, initialStock: 25, category: .main, unitCost: 6,
        retailPrice: 12, meaning: "体贴、高雅"
      ).withTags(["western", "universal"]),
      FlowerType(
        name: "红玫瑰", color: "#DC143C", quantity: 60, initialStock: 60, category: .main, unitCost: 6,
        retailPrice: 15, meaning: "热烈的爱"
      ).withTags(["western", "universal"]),
      FlowerType(
        name: "粉康乃馨", color: "#FFB6C1", quantity: 40, initialStock: 40, category: .main,
        unitCost: 4, retailPrice: 10, meaning: "母爱、感激"
      ).withTags(["western", "universal"]),
      FlowerType(
        name: "扶郎花", color: "#FFA500", quantity: 30, initialStock: 30, category: .main, unitCost: 3,
        retailPrice: 8, meaning: "互敬互爱、有毅力"
      ).withTags(["western", "universal"]),
      FlowerType(
        name: "洋桔梗", color: "#E6E6FA", quantity: 30, initialStock: 30, category: .main, unitCost: 8,
        retailPrice: 18, meaning: "真诚不变的爱"
      ).withTags(["western", "universal"]),
      FlowerType(
        name: "满天星", color: "#FFFFFF", quantity: 50, initialStock: 50, category: .filler,
        unitCost: 15, retailPrice: 35, meaning: "清纯、配角之爱"
      ).withTags(["western", "universal"]),
      FlowerType(
        name: "龟背竹", color: "#228B22", quantity: 20, initialStock: 20, category: .foliage,
        unitCost: 6, retailPrice: 15, meaning: "健康长寿"
      ).withTags(["western", "universal"]),
      FlowerType(
        name: "天堂鸟", color: "#FF8C00", quantity: 10, initialStock: 10, category: .main,
        unitCost: 18, retailPrice: 45, meaning: "自由、潇洒"
      ).withTags(["western", "universal"]),

      // 中式传统花材
      FlowerType(
        name: "梅枝", color: "#FF6B8A", quantity: 15, initialStock: 15, category: .main, unitCost: 12,
        retailPrice: 28, meaning: "傲骨凌霜、高洁"
      ).withTags(["chinese"]),
      FlowerType(
        name: "兰花", color: "#E6E6FA", quantity: 10, initialStock: 10, category: .main, unitCost: 25,
        retailPrice: 60, meaning: "高洁雅士、君子之风"
      ).withTags(["chinese", "western"]),
      FlowerType(
        name: "竹枝", color: "#228B22", quantity: 30, initialStock: 30, category: .foliage,
        unitCost: 5, retailPrice: 12, meaning: "虚怀若谷、清雅脱俗"
      ).withTags(["chinese", "japanese"]),
      FlowerType(
        name: "菊花", color: "#FFD700", quantity: 25, initialStock: 25, category: .main, unitCost: 8,
        retailPrice: 18, meaning: "长寿高洁、隐逸清雅"
      ).withTags(["chinese", "japanese"]),
      FlowerType(
        name: "水仙", color: "#FFFACD", quantity: 20, initialStock: 20, category: .main, unitCost: 10,
        retailPrice: 22, meaning: "高洁孤傲、思念"
      ).withTags(["chinese"]),
      FlowerType(
        name: "芍药", color: "#FFB6C1", quantity: 12, initialStock: 12, category: .main, unitCost: 18,
        retailPrice: 42, meaning: "娇羞之美、情有独钟"
      ).withTags(["chinese", "western"]),

      // 日式传统花材
      FlowerType(
        name: "樱花枝", color: "#FFB7C5", quantity: 8, initialStock: 8, category: .main, unitCost: 20,
        retailPrice: 48, meaning: "生命无常、美的瞬间"
      ).withTags(["japanese"]),
      FlowerType(
        name: "椿花", color: "#DC143C", quantity: 10, initialStock: 10, category: .main, unitCost: 15,
        retailPrice: 35, meaning: "完美之爱、谦逊"
      ).withTags(["japanese"]),
      FlowerType(
        name: "松枝", color: "#2F4F4F", quantity: 25, initialStock: 25, category: .foliage,
        unitCost: 8, retailPrice: 18, meaning: "坚忍不拔、永恒"
      ).withTags(["japanese", "chinese"]),
      FlowerType(
        name: "桃花枝", color: "#FFB6C1", quantity: 12, initialStock: 12, category: .main,
        unitCost: 12, retailPrice: 28, meaning: "春意盎然、桃花运"
      ).withTags(["japanese", "chinese"]),

      // 中式扩展
      FlowerType(
        name: "牡丹", color: "#FF1493", quantity: 15, initialStock: 15, category: .main, unitCost: 25,
        retailPrice: 68, meaning: "圆满、富贵、吉祥"
      ).withTags(["chinese"]),
      FlowerType(
        name: "海棠", color: "#FF69B4", quantity: 10, initialStock: 10, category: .main, unitCost: 18,
        retailPrice: 45, meaning: "游子思乡、温和"
      ).withTags(["chinese"]),
      FlowerType(
        name: "红豆", color: "#FF0000", quantity: 40, initialStock: 40, category: .filler,
        unitCost: 5, retailPrice: 12, meaning: "相思、喜庆"
      ).withTags(["chinese", "universal"]),

      // 日式扩展
      FlowerType(
        name: "花菖蒲", color: "#8A2BE2", quantity: 15, initialStock: 15, category: .main,
        unitCost: 12, retailPrice: 28, meaning: "优雅的心、信者之福"
      ).withTags(["japanese"]),
      FlowerType(
        name: "枫叶枝", color: "#B22222", quantity: 20, initialStock: 20, category: .foliage,
        unitCost: 10, retailPrice: 25, meaning: "秋之回忆、自制"
      ).withTags(["japanese", "chinese"]),
      FlowerType(
        name: "文心兰", color: "#FFFF00", quantity: 25, initialStock: 25, category: .filler,
        unitCost: 8, retailPrice: 20, meaning: "快乐无忧"
      ).withTags(["japanese", "western"]),

      // 欧式扩展
      FlowerType(
        name: "洋牡丹", color: "#FFDAB9", quantity: 30, initialStock: 30, category: .main,
        unitCost: 10, retailPrice: 25, meaning: "迷人的魅力"
      ).withTags(["western"]),
      FlowerType(
        name: "飞燕草", color: "#4169E1", quantity: 15, initialStock: 15, category: .main,
        unitCost: 12, retailPrice: 30, meaning: "清静、正义、自由"
      ).withTags(["western"]),
      FlowerType(
        name: "银莲花", color: "#800080", quantity: 20, initialStock: 20, category: .main,
        unitCost: 10, retailPrice: 22, meaning: "期待、没有结果的爱"
      ).withTags(["western"]),
      FlowerType(
        name: "尤加利果", color: "#556B2F", quantity: 50, initialStock: 50, category: .foliage,
        unitCost: 6, retailPrice: 15, meaning: "恩赐、回忆"
      ).withTags(["western", "universal"]),
    ]
  }
}

// Helper extension to add tags fluently
extension FlowerType {
  func withTags(_ tags: [String]) -> FlowerType {
    var copy = self
    copy.cultureTags = tags
    return copy
  }
}
