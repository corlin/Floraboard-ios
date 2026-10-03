//
//  LegalFooterView.swift
//  Floreboard
//
//  A reusable, compliant legal & support footer component.
//

import SwiftUI
import UIKit

struct LegalFooterView: View {
  @EnvironmentObject private var loc: LocalizationManager
  @State private var activeDocument: LegalDocumentType? = nil
  @State private var showCopiedToast: Bool = false

  var body: some View {
    VStack(spacing: 8) {
      // Legal Links Row
      HStack(spacing: 8) {
        Button {
          activeDocument = .privacy
        } label: {
          Text(loc.t("legal.privacyPolicy"))
            .font(AppTheme.captionSmall)
            .foregroundColor(AppTheme.mutedText)
            .underline()
        }

        Text("•")
          .font(AppTheme.captionSmall)
          .foregroundColor(AppTheme.mutedText.opacity(0.6))

        Button {
          activeDocument = .terms
        } label: {
          Text(loc.t("legal.termsOfService"))
            .font(AppTheme.captionSmall)
            .foregroundColor(AppTheme.mutedText)
            .underline()
        }

        Text("•")
          .font(AppTheme.captionSmall)
          .foregroundColor(AppTheme.mutedText.opacity(0.6))

        Button {
          activeDocument = .refund
        } label: {
          Text(loc.t("legal.refundPolicy"))
            .font(AppTheme.captionSmall)
            .foregroundColor(AppTheme.mutedText)
            .underline()
        }
      }

      // Contact & Support Row
      Button {
        handleEmailTap()
      } label: {
        HStack(spacing: 4) {
          Image(systemName: "envelope.fill")
            .font(.system(size: 10))
          Text(loc.t("legal.support", ["email": LegalConfig.contactEmail]))
            .font(AppTheme.captionSmall)
        }
        .foregroundColor(AppTheme.mutedText)
      }
      .buttonStyle(.plain)

      // Copied Toast
      if showCopiedToast {
        HStack(spacing: 6) {
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 11))
            .foregroundColor(AppTheme.success)
          Text(loc.t("legal.emailCopied"))
            .font(AppTheme.captionSmall)
            .foregroundColor(AppTheme.foreground)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(AppTheme.surfaceElevated)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppTheme.hairline, lineWidth: 1))
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .sheet(item: $activeDocument) { doc in
      LegalDocumentView(documentType: doc)
        .environmentObject(loc)
    }
  }

  private func handleEmailTap() {
    HapticManager.shared.impact(style: .light)
    if let mailURL = LegalConfig.supportMailURL, UIApplication.shared.canOpenURL(mailURL) {
      UIApplication.shared.open(mailURL)
    } else {
      UIPasteboard.general.string = LegalConfig.contactEmail
      HapticManager.shared.notification(type: .success)
      withAnimation(.easeInOut(duration: 0.25)) {
        showCopiedToast = true
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        withAnimation(.easeInOut(duration: 0.25)) {
          showCopiedToast = false
        }
      }
    }
  }
}
