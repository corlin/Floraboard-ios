//
//  DesignMerge.swift
//  Floreboard
//
//  本地与云端方案的合并规则，以及图片地址/时间戳的判断。纯 Swift，不依赖 UIKit，便于单独测试。
//

import Foundation

enum DesignMerge {

  // MARK: - 图片地址

  /// 是否为可跨设备访问的远程地址（R2 / CDN）。本地文件名（如 "UUID.jpg"）返回 false。
  static func isRemoteImage(_ value: String?) -> Bool {
    guard let value, !value.isEmpty else { return false }
    let lower = value.lowercased()
    return lower.hasPrefix("http://") || lower.hasPrefix("https://")
  }

  /// 图片地址的“靠前程度”：远程 URL > 本地文件名 > 空。
  private static func imageRank(_ value: String?) -> Int {
    if isRemoteImage(value) { return 2 }
    if let value, !value.isEmpty { return 1 }
    return 0
  }

  private static func imageStatusRank(_ status: ImageStatus?) -> Int {
    switch status {
    case .succeeded: return 3
    case .failed: return 2
    case .generating, .pending: return 1
    case .none: return 0
    }
  }

  // MARK: - 时间戳

  /// 云端（网页/服务端）使用毫秒，iOS 本地使用秒。大于 1e11 的值按毫秒处理。
  static func seconds(_ value: Double) -> Double {
    value > 1e11 ? value / 1000 : value
  }

  static func normalizedTimestamps(_ design: DesignResult) -> DesignResult {
    var d = design
    d.createdAt = seconds(design.createdAt)
    if let executed = design.executedAt { d.executedAt = seconds(executed) }
    return d
  }

  // MARK: - 合并

  /// 合并本地与云端的同一份方案。
  ///
  /// 以云端为基础（它带着其他设备的改动），但下面这些字段“只会向前推进”，
  /// 本地更靠前就保留本地，避免一份旧的云端副本把它们回退：
  /// - 状态：已执行 > 草稿（执行时间随之保留）
  /// - 图片地址：远程 URL > 本地文件名 > 空
  /// - 出图状态：成功 > 失败 > 生成中 > 无（成功后清除错误信息）
  /// - 评分/评价：本地有、云端没有时保留本地
  static func merge(local: DesignResult, cloud: DesignResult) -> DesignResult {
    var merged = cloud

    if local.status == .completed && cloud.status != .completed {
      merged.status = .completed
      merged.executedAt = local.executedAt ?? cloud.executedAt
    }

    if imageRank(local.imageUrl) > imageRank(cloud.imageUrl) {
      merged.imageUrl = local.imageUrl
    }

    if imageStatusRank(local.imageStatus) > imageStatusRank(cloud.imageStatus) {
      merged.imageStatus = local.imageStatus
      merged.imageError = local.imageError
    }
    if merged.imageStatus == .succeeded { merged.imageError = nil }

    if merged.rating == nil { merged.rating = local.rating }
    if (merged.feedback ?? "").isEmpty { merged.feedback = local.feedback }
    if (merged.imagePrompt ?? "").isEmpty { merged.imagePrompt = local.imagePrompt }

    // 生成参数与校验结果以云端为准（服务端计算）；云端没有时保留本地
    if merged.request == nil { merged.request = local.request }
    if merged.findings == nil { merged.findings = local.findings }

    // 参考图只存在于本机，云端没有这个字段
    merged.referenceImageUrl = local.referenceImageUrl ?? cloud.referenceImageUrl
    return merged
  }

  /// 合并结果与云端副本在“需要同步”的字段上是否不同（不同则应把合并结果推回云端）。
  static func needsPush(merged: DesignResult, cloud: DesignResult) -> Bool {
    merged.status != cloud.status
      || merged.executedAt != cloud.executedAt
      || merged.imageUrl != cloud.imageUrl
      || merged.imageStatus != cloud.imageStatus
      || merged.rating != cloud.rating
      || (merged.feedback ?? "") != (cloud.feedback ?? "")
  }
}
