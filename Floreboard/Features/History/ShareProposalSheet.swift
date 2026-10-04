//
//  ShareProposalSheet.swift
//  Floreboard
//
//  把方案发给客户：生成分享链接，用系统分享表单发到微信 / 短信等；客户可在网页上确认或提出调整。
//  文案来自网页端语言包（ProductionStrings，designDetail.share.*）。
//

import SwiftUI

struct ShareProposalSheet: View {
  let designId: String
  @EnvironmentObject var historyService: HistoryService
  @Environment(\.dismiss) private var dismiss

  @State private var share: ProposalShare?
  @State private var isBusy = false
  @State private var errorText: String?

  init(designId: String, share: ProposalShare?) {
    self.designId = designId
    self._share = State(initialValue: share)
  }

  private func t(_ key: String) -> String { ProductionStrings.t("designDetail.share.\(key)") }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Text(t("hint"))
            .font(AppTheme.sansFont(size: 14))
            .foregroundColor(AppTheme.mutedText)
        }

        if let share, let url = share.url {
          Section {
            Text(url.absoluteString)
              .font(AppTheme.sansFont(size: 13))
              .textSelection(.enabled)
            ShareLink(item: url) {
              Label(t("button"), systemImage: "square.and.arrow.up")
            }
            Toggle(t("showPrice"), isOn: Binding(
              get: { share.showPrice == true },
              set: { value in Task { await save(showPrice: value) } }
            ))
            .disabled(isBusy)
          } footer: {
            Text(t("privacy"))
          }

          Section {
            Button(role: .destructive) {
              Task { await revoke() }
            } label: {
              Label(t("revoke"), systemImage: "trash")
            }
            .disabled(isBusy)
          }
        } else if isBusy {
          Section { ProgressView() }
        }

        if let errorText {
          Section { Text(errorText).foregroundColor(AppTheme.danger) }
        }
      }
      .navigationTitle(t("title"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(t("done")) { dismiss() }
        }
      }
      .task {
        if share == nil { await save(showPrice: false) }
      }
    }
  }

  private func save(showPrice: Bool) async {
    isBusy = true
    defer { isBusy = false }
    do {
      let updated = try await AIService.shared.shareDesign(id: designId, showPrice: showPrice)
      share = updated
      errorText = nil
      historyService.applyShare(id: designId, updated)
    } catch {
      errorText = t("failed")
    }
  }

  private func revoke() async {
    isBusy = true
    defer { isBusy = false }
    do {
      try await AIService.shared.unshareDesign(id: designId)
      share = nil
      historyService.applyShare(id: designId, nil)
      dismiss()
    } catch {
      errorText = t("failed")
    }
  }
}

/// 客户在分享页上的反馈
struct ClientResponseBanner: View {
  let response: ClientResponse

  var body: some View {
    let tint = response.isApproved ? AppTheme.success : AppTheme.warning
    VStack(alignment: .leading, spacing: 6) {
      Label(
        ProductionStrings.t(response.isApproved ? "designDetail.share.clientApproved" : "designDetail.share.clientChanges"),
        systemImage: response.isApproved ? "hand.thumbsup.fill" : "text.bubble.fill"
      )
      .font(AppTheme.sansFont(size: 15, weight: .semibold))
      .foregroundColor(tint)
      if let note = response.note, !note.isEmpty {
        Text("“\(note)”")
          .font(AppTheme.sansFont(size: 14))
          .foregroundColor(AppTheme.foreground)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(tint.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
  }
}

/// 方案详情页顶部：客户反馈（如有）+“发给客户”按钮
struct ShareProposalSection: View {
  let design: DesignResult
  @EnvironmentObject var historyService: HistoryService
  @State private var showShareSheet = false

  var body: some View {
    VStack(spacing: 12) {
      if let response = design.clientResponse {
        ClientResponseBanner(response: response)
      }
      Button {
        showShareSheet = true
      } label: {
        Label(ProductionStrings.t("designDetail.share.button"), systemImage: "paperplane.fill")
          .font(AppTheme.sansFont(size: 15, weight: .semibold))
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .foregroundColor(AppTheme.iconOnAccent)
          .background(AppTheme.primary)
          .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
      }
    }
    .padding(.horizontal)
    .padding(.top, 12)
    .sheet(isPresented: $showShareSheet) {
      ShareProposalSheet(designId: design.id, share: design.share)
        .environmentObject(historyService)
    }
  }
}
