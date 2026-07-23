//
//  ImageCompressor.swift
//  Floreboard
//
//  Scales down and compresses reference images before uploading to AI Proxy.
//

import UIKit

struct ImageCompressor {
  static func compressImage(_ image: UIImage, maxDimension: CGFloat = 1280, quality: CGFloat = 0.75) -> Data? {
    let size = image.size
    let width = size.width
    let height = size.height

    if width <= maxDimension && height <= maxDimension {
      return image.jpegData(compressionQuality: quality)
    }

    let scale: CGFloat
    if width > height {
      scale = maxDimension / width
    } else {
      scale = maxDimension / height
    }

    let newSize = CGSize(width: width * scale, height: height * scale)

    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: CGRect(origin: .zero, size: newSize))
    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return resizedImage?.jpegData(compressionQuality: quality)
  }
}
