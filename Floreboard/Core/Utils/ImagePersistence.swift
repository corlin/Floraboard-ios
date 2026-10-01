//
//  ImagePersistence.swift
//  Floreboard
//
//  Created by AI Assistant.
//

import Foundation
import UIKit
import OSLog

class ImagePersistence {
  static let shared = ImagePersistence()

  private let fileManager = FileManager.default
  private let cache: NSCache<NSString, UIImage> = {
    let cache = NSCache<NSString, UIImage>()
    cache.countLimit = 50
    cache.totalCostLimit = 100 * 1024 * 1024 // 100MB
    return cache
  }()

  private var documentsDirectory: URL {
    fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
  }

  func saveImage(_ image: UIImage, name: String) -> String? {
    let fileName = "\(name).jpg"
    let fileURL = documentsDirectory.appendingPathComponent(fileName)

    // Cache immediately
    cache.setObject(image, forKey: fileName as NSString)

    guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }

    do {
      try data.write(to: fileURL)
      return fileName
    } catch {
      AppLogger.image.error("Error saving image: \(error)")
      return nil
    }
  }

  /// 把已经拿到手的图片写入“远程地址”的磁盘/内存缓存，避免随后再下载一次。
  func cacheRemote(_ image: UIImage, for urlString: String) {
    cache.setObject(image, forKey: urlString as NSString)
    let sanitizedKey = urlString.replacingOccurrences(of: "[^a-zA-Z0-9_.-]", with: "_", options: .regularExpression)
    let diskFileName = "cached_\(sanitizedKey.suffix(40)).jpg"
    let fileURL = documentsDirectory.appendingPathComponent(diskFileName)
    if let data = image.jpegData(compressionQuality: 0.8) {
      try? data.write(to: fileURL)
    }
  }

  func loadImage(named fileName: String) -> UIImage? {
    // Check cache first
    if let cachedImage = cache.object(forKey: fileName as NSString) {
      return cachedImage
    }

    // Check remote URL disk cache if applicable
    if fileName.hasPrefix("http://") || fileName.hasPrefix("https://") {
      let sanitizedKey = fileName.replacingOccurrences(of: "[^a-zA-Z0-9_.-]", with: "_", options: .regularExpression)
      let diskFileName = "cached_\(sanitizedKey.suffix(40)).jpg"
      let fileURL = documentsDirectory.appendingPathComponent(diskFileName)
      if fileManager.fileExists(atPath: fileURL.path),
         let diskData = try? Data(contentsOf: fileURL),
         let diskImage = UIImage(data: diskData) {
        cache.setObject(diskImage, forKey: fileName as NSString)
        return diskImage
      }
      return nil
    }

    let fileURL = documentsDirectory.appendingPathComponent(fileName)
    guard fileManager.fileExists(atPath: fileURL.path) else { return nil }

    do {
      let data = try Data(contentsOf: fileURL)
      if let image = UIImage(data: data) {
        // Store in cache
        cache.setObject(image, forKey: fileName as NSString)
        return image
      }
      return nil
    } catch {
      AppLogger.image.error("Error loading image: \(error)")
      return nil
    }
  }

  /// Loads an image asynchronously by local filename or remote HTTP/HTTPS URL with disk & memory cache.
  func loadImageAsync(namedOrURL path: String) async -> UIImage? {
    // 1. Check memory cache first
    if let cachedImage = cache.object(forKey: path as NSString) {
      return cachedImage
    }

    // 2. Handle remote URL (e.g. Cloudflare R2 / CDN)
    if path.hasPrefix("http://") || path.hasPrefix("https://") {
      guard let url = URL(string: path) else { return nil }

      let sanitizedKey = path.replacingOccurrences(of: "[^a-zA-Z0-9_.-]", with: "_", options: .regularExpression)
      let diskFileName = "cached_\(sanitizedKey.suffix(40)).jpg"
      let fileURL = documentsDirectory.appendingPathComponent(diskFileName)

      // Check disk cache
      if fileManager.fileExists(atPath: fileURL.path),
         let diskData = try? Data(contentsOf: fileURL),
         let diskImage = UIImage(data: diskData) {
        cache.setObject(diskImage, forKey: path as NSString)
        return diskImage
      }

      // Download from remote URL
      do {
        let (data, response) = try await URLSession.shared.data(from: url)
        if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode),
           let image = UIImage(data: data) {
          try? data.write(to: fileURL)
          cache.setObject(image, forKey: path as NSString)
          return image
        }
      } catch {
        AppLogger.image.error("Error downloading remote image \(path): \(error)")
      }
      return nil
    }

    // 3. Fallback to local synchronous loader
    return loadImage(named: path)
  }

  func deleteImage(named fileName: String) {
    cache.removeObject(forKey: fileName as NSString)
    let fileURL = documentsDirectory.appendingPathComponent(fileName)
    try? fileManager.removeItem(at: fileURL)
  }
}
