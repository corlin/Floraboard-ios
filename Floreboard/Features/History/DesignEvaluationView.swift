//
//  DesignEvaluationView.swift
//  Floreboard
//
//  方案评价：评分（1–5 星）+ 心得/客户反馈。保存后随方案同步到云端（网页端同样可见）。
//

import SwiftUI

struct DesignEvaluationView: View {
  let initialRating: Int
  let initialFeedback: String
  let onSave: (_ rating: Int, _ feedback: String) -> Void

  @State private var rating: Int
  @State private var feedback: String
  @State private var savedFlash = false

  init(rating: Int?, feedback: String?, onSave: @escaping (_ rating: Int, _ feedback: String) -> Void) {
    initialRating = rating ?? 0
    initialFeedback = feedback ?? ""
    self.onSave = onSave
    _rating = State(initialValue: rating ?? 0)
    _feedback = State(initialValue: feedback ?? "")
  }

  private var changed: Bool { rating != initialRating || feedback != initialFeedback }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Label(ProductionStrings.t("designDetail.evaluation.title"), systemImage: "star.bubble")
        .font(AppTheme.sansFont(size: 14, weight: .semibold))
        .foregroundColor(AppTheme.foreground)

      VStack(alignment: .leading, spacing: 6) {
        Text(ProductionStrings.t("designDetail.evaluation.rating"))
          .font(AppTheme.sansFont(size: 12)).foregroundColor(AppTheme.mutedText)
        HStack(spacing: 8) {
          ForEach(1...5, id: \.self) { star in
            Button {
              rating = (rating == star) ? 0 : star  // 再点一次同一颗星取消评分
            } label: {
              Image(systemName: star <= rating ? "star.fill" : "star")
                .font(.system(size: 26))
                .foregroundColor(star <= rating ? .yellow : AppTheme.mutedText.opacity(0.5))
            }
            .buttonStyle(.plain)
          }
        }
      }

      VStack(alignment: .leading, spacing: 6) {
        Text(ProductionStrings.t("designDetail.evaluation.feedback"))
          .font(AppTheme.sansFont(size: 12)).foregroundColor(AppTheme.mutedText)
        TextField(
          ProductionStrings.t("designDetail.evaluation.placeholder"), text: $feedback, axis: .vertical
        )
        .lineLimit(3...6)
        .font(AppTheme.sansFont(size: 15))
        .padding(10)
        .background(RoundedRectangle(cornerRadius: AppTheme.chipRadius, style: .continuous).fill(AppTheme.primary.opacity(0.06)))
      }

      Button {
        onSave(rating, feedback.trimmingCharacters(in: .whitespacesAndNewlines))
        savedFlash = true
      } label: {
        HStack {
          Image(systemName: savedFlash && !changed ? "checkmark" : "square.and.arrow.down")
          Text(ProductionStrings.t("designDetail.evaluation.saveBtn"))
        }
        .font(AppTheme.sansFont(size: 15, weight: .semibold))
        .foregroundColor(AppTheme.iconOnAccent)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: AppTheme.controlRadius).fill(AppTheme.primary.opacity(changed ? 1 : 0.35)))
      }
      .disabled(!changed)
    }
    .padding()
    .glassmorphic()
    .padding(.horizontal)
    .onChange(of: rating) { _, _ in savedFlash = false }
    .onChange(of: feedback) { _, _ in savedFlash = false }
  }
}
