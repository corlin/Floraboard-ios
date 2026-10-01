//
//  ImageSyncService.swift
//  Floreboard
//
//  让方案图片可以跨设备访问：存到云端并把“可访问的 URL”记在方案上，而不是只存手机本地的文件名。
//  历史问题：出图后图片只保存为本地文件（如 "UUID.jpg"），并把这个文件名同步到云端，
//  于是网页和其他设备永远看不到图片，云端也无法显示。
//

import Foundation
import OSLog
import UIKit

@MainActor
final class ImageSyncService {
  static let shared = ImageSyncService()
  private var isHealing = false
  private init() {}

  /// 决定方案的 `imageUrl` 应该保存什么，优先级：
  /// 1. 服务端已经给了可访问的 URL（R2）→ 直接使用，并把已下载的图片写入缓存；
  /// 2. 只有图片本身（如 base64、用户选的参考图）→ 上传到云端换取 URL；
  /// 3. 上传失败（离线等）→ 退回本地文件名，保证本机仍能显示，稍后由 `healLocalImages` 补传。
  /// 无论哪种，都会在本地保留一份文件作为兜底。
  func storedImageValue(
    image: UIImage,
    remoteURL: String?,
    designId: String,
    persistence: ImagePersistence
  ) async -> String? {
    let localFilename = persistence.saveImage(image, name: designId)

    if let remote = remoteURL, DesignMerge.isRemoteImage(remote) {
      persistence.cacheRemote(image, for: remote)
      return remote
    }
    if let uploaded = await upload(image, persistence: persistence) {
      return uploaded
    }
    return localFilename
  }

  private func upload(_ image: UIImage, persistence: ImagePersistence) async -> String? {
    guard let tenantId = AuthService.shared.currentTenant?.id,
          let data = image.jpegData(compressionQuality: 0.85),
          let client = try? AIService.shared.makeProxyClient() else { return nil }
    do {
      let url = try await client.uploadImage(data, tenantId: tenantId)
      persistence.cacheRemote(image, for: url)
      return url
    } catch {
      AppLogger.image.warning("Image upload failed, keeping local file: \(error.localizedDescription)")
      return nil
    }
  }

  /// 补传：把仍指向“本地文件名”的方案图片上传，换成可访问的 URL 并同步到云端。
  /// 只处理本机上确实存在文件的方案；失败的下次再试，不会反复打扰。
  func healLocalImages(history: HistoryService, persistence: ImagePersistence = .shared) async {
    guard !isHealing else { return }
    isHealing = true
    defer { isHealing = false }

    let candidates = history.savedDesigns.filter { design in
      guard let url = design.imageUrl, !url.isEmpty else { return false }
      return !DesignMerge.isRemoteImage(url)
    }
    for design in candidates {
      guard let name = design.imageUrl,
            let image = persistence.loadImage(named: name) else { continue }
      guard let uploaded = await upload(image, persistence: persistence) else { continue }
      var healed = design
      healed.imageUrl = uploaded
      if healed.imageStatus != .succeeded {
        healed.imageStatus = .succeeded
        healed.imageError = nil
      }
      history.saveDesign(healed)
      AppLogger.image.info("Healed local image for design \(design.id)")
    }
  }
}
