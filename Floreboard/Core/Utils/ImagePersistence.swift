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

  func loadImage(named fileName: String) -> UIImage? {
    // Check cache first
    if let cachedImage = cache.object(forKey: fileName as NSString) {
      return cachedImage
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

  func deleteImage(named fileName: String) {
    cache.removeObject(forKey: fileName as NSString)
    let fileURL = documentsDirectory.appendingPathComponent(fileName)
    try? fileManager.removeItem(at: fileURL)
  }
}
