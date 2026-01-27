//
//  ZoomableImageView.swift
//  Floreboard
//
//  Created by AI Assistant.
//

import SwiftUI
import UIKit

struct ZoomableImageView: UIViewRepresentable {
  let image: UIImage

  func makeUIView(context: Context) -> UIScrollView {
    let scrollView = UIScrollView()
    scrollView.delegate = context.coordinator
    scrollView.maximumZoomScale = 5.0
    scrollView.minimumZoomScale = 1.0
    scrollView.bouncesZoom = true
    scrollView.backgroundColor = .black
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.showsVerticalScrollIndicator = false

    let imageView = UIImageView(image: image)
    imageView.contentMode = .scaleAspectFit
    imageView.translatesAutoresizingMaskIntoConstraints = false

    scrollView.addSubview(imageView)

    // Constraints to keep image centered/sizable
    NSLayoutConstraint.activate([
      imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
      imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
      imageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
      imageView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
    ])

    // Double tap gesture
    let doubleTap = UITapGestureRecognizer(
      target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
    doubleTap.numberOfTapsRequired = 2
    scrollView.addGestureRecognizer(doubleTap)

    return scrollView
  }

  func updateUIView(_ uiView: UIScrollView, context: Context) {
    // Find the UIImageView inside
    if let imageView = uiView.subviews.first(where: { $0 is UIImageView }) as? UIImageView {
      imageView.image = image
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, UIScrollViewDelegate {
    var parent: ZoomableImageView

    init(_ parent: ZoomableImageView) {
      self.parent = parent
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
      return scrollView.subviews.first(where: { $0 is UIImageView })
    }

    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
      guard let scrollView = gesture.view as? UIScrollView else { return }

      if scrollView.zoomScale > 1.0 {
        scrollView.setZoomScale(1.0, animated: true)
      } else {
        let point = gesture.location(in: scrollView)
        // Zoom to rect logic or simple 2x
        let zoomRect = zoomRectForScale(scale: 2.5, center: point, scrollView: scrollView)
        scrollView.zoom(to: zoomRect, animated: true)
      }
    }

    func zoomRectForScale(scale: CGFloat, center: CGPoint, scrollView: UIScrollView) -> CGRect {
      var zoomRect = CGRect.zero
      zoomRect.size.height = scrollView.frame.size.height / scale
      zoomRect.size.width = scrollView.frame.size.width / scale
      let newCenter = scrollView.convert(center, from: scrollView)
      zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
      zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
      return zoomRect
    }
  }
}

// Wrapper for Full Screen
struct FullScreenImageView: View {
  let image: UIImage
  @Environment(\.presentationMode) var presentationMode

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      ZoomableImageView(image: image)
        .ignoresSafeArea()

      // Overlay controls
      VStack {
        HStack {
          Spacer()
          Button(action: {
            presentationMode.wrappedValue.dismiss()
          }) {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 30))
              .foregroundColor(.white.opacity(0.8))
              .padding()
              .background(Circle().fill(Color.black.opacity(0.4)))
          }
          .padding(.top, 40)
          .padding(.trailing, 20)
        }
        Spacer()
      }
    }
    .statusBar(hidden: true)
  }
}
