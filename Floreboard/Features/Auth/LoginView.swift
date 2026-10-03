import SwiftUI

struct LoginView: View {
  @EnvironmentObject var auth: AuthService
  @EnvironmentObject var loc: LocalizationManager

  @State private var email = ""
  @State private var password = ""
  @State private var shopName = ""
  @State private var isRegistering = false
  @State private var isPasswordVisible = false
  @State private var showingTerms = false
  @State private var showingPrivacy = false
  @FocusState private var focusedField: AuthField?

  enum AuthField: Hashable {
    case shopName, email, password
  }

  // MARK: - Refined Palette Tokens
  private let royalForestGreen = Color(red: 0.075, green: 0.224, blue: 0.145) // #133925 - Deep Royal Atelier Green
  private let royalForestGreenDisabled = Color(red: 0.075, green: 0.224, blue: 0.145).opacity(0.35)
  private let titleCharcoal = Color(red: 0.11, green: 0.12, blue: 0.11) // #1C1F1D - High-contrast luxury black
  private let subtitleMuted = Color(red: 0.44, green: 0.47, blue: 0.45) // Clear readable slate
  private let fieldBorderNormal = Color(red: 0.82, green: 0.84, blue: 0.82)
  private let placeholderGray = Color(red: 0.50, green: 0.53, blue: 0.51)
  private let goldAccent = Color(red: 0.72, green: 0.58, blue: 0.40)

  var body: some View {
    NavigationStack {
      ZStack {
        // 1. 朦胧叶影晨光背景（纯净高保真）
        Image("MistyShadowBg")
          .resizable()
          .scaledToFill()
          .ignoresSafeArea()

        VStack(spacing: 0) {

          // 顶部小巧精致的多语言胶囊（右上角轻悬浮）
          HStack {
            Spacer()
            Menu {
              ForEach(Language.allCases) { lang in
                Button {
                  loc.currentLanguage = lang
                } label: {
                  HStack {
                    Text(lang.displayName)
                    if loc.currentLanguage == lang {
                      Image(systemName: "checkmark")
                    }
                  }
                }
              }
            } label: {
              HStack(spacing: 5) {
                Text(loc.currentLanguage.rawValue.uppercased())
                  .font(.system(size: 13, weight: .semibold))
                  .foregroundColor(titleCharcoal)
                Image(systemName: "chevron.down")
                  .font(.system(size: 9, weight: .bold))
                  .foregroundColor(subtitleMuted)
              }
              .padding(.horizontal, 14)
              .padding(.vertical, 7)
              .background(Color.white.opacity(0.92))
              .clipShape(Capsule())
              .overlay(
                Capsule().stroke(fieldBorderNormal.opacity(0.6), lineWidth: 1)
              )
              .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            }
          }
          .padding(.horizontal, 28)
          .padding(.top, 8)

          ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {

              // 2. 品牌纹章与标题区域（专业黄金比例，纹章 136pt，纯正 FloraBoard 品牌大标）
              VStack(spacing: 12) {
                Image("AtelierEmblem")
                  .resizable()
                  .scaledToFit()
                  .frame(height: 136)
                  .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)

                VStack(spacing: 6) {
                  Text(loc.t("auth.title"))
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundColor(titleCharcoal)
                    .tracking(0.8)

                  Text(loc.t("auth.subtitle"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(subtitleMuted)
                    .tracking(0.6)
                }
              }
              .padding(.top, 4)
              .padding(.bottom, 24)

              // 3. 悬浮操作卡片（纯白邀请函质感，两侧留白 32pt，优雅挺拔）
              VStack(spacing: 18) {

                // 登录 / 注册 分段药丸切换
                HStack(spacing: 0) {
                  Button {
                    withAnimation(.easeInOut(duration: 0.16)) {
                      isRegistering = false
                      auth.errorMessage = nil
                    }
                  } label: {
                    Text(loc.t("auth.tabs.signIn"))
                      .font(.system(size: 14.5, weight: isRegistering ? .regular : .semibold))
                      .foregroundColor(isRegistering ? subtitleMuted : titleCharcoal)
                      .frame(maxWidth: .infinity)
                      .padding(.vertical, 10)
                      .background(
                        Group {
                          if !isRegistering {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                              .fill(Color.white)
                              .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                          }
                        }
                      )
                  }
                  .buttonStyle(.plain)

                  Button {
                    withAnimation(.easeInOut(duration: 0.16)) {
                      isRegistering = true
                      auth.errorMessage = nil
                    }
                  } label: {
                    Text(loc.t("auth.tabs.signUp"))
                      .font(.system(size: 14.5, weight: isRegistering ? .semibold : .regular))
                      .foregroundColor(isRegistering ? titleCharcoal : subtitleMuted)
                      .frame(maxWidth: .infinity)
                      .padding(.vertical, 10)
                      .background(
                        Group {
                          if isRegistering {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                              .fill(Color.white)
                              .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                          }
                        }
                      )
                  }
                  .buttonStyle(.plain)
                }
                .padding(3.5)
                .background(Color(red: 0.93, green: 0.94, blue: 0.93))
                .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))

                // 4. 输入框区域（标准胶囊药丸，高对比度清晰字）
                VStack(spacing: 13) {
                  if isRegistering {
                    HStack(spacing: 12) {
                      Image(systemName: "storefront")
                        .font(.system(size: 15))
                        .foregroundColor(focusedField == .shopName ? royalForestGreen : subtitleMuted)
                        .frame(width: 20)

                      ZStack(alignment: .leading) {
                        if shopName.isEmpty {
                          Text(loc.t("auth.fields.shopName"))
                            .font(.system(size: 15))
                            .foregroundColor(placeholderGray)
                        }
                        TextField("", text: $shopName)
                          .font(.system(size: 15))
                          .foregroundColor(titleCharcoal)
                          .focused($focusedField, equals: .shopName)
                          .autocapitalization(.words)
                      }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 13)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .overlay(
                      Capsule()
                        .stroke(focusedField == .shopName ? royalForestGreen : fieldBorderNormal, lineWidth: focusedField == .shopName ? 1.5 : 1)
                    )
                    .transition(.opacity)
                  }

                  HStack(spacing: 12) {
                    Image(systemName: "envelope")
                      .font(.system(size: 15))
                      .foregroundColor(focusedField == .email ? royalForestGreen : subtitleMuted)
                      .frame(width: 20)

                    ZStack(alignment: .leading) {
                      if email.isEmpty {
                        Text(loc.t("auth.fields.email"))
                          .font(.system(size: 15))
                          .foregroundColor(placeholderGray)
                      }
                      TextField("", text: $email)
                        .font(.system(size: 15))
                        .foregroundColor(titleCharcoal)
                        .focused($focusedField, equals: .email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    }
                  }
                  .padding(.horizontal, 18)
                  .padding(.vertical, 13)
                  .background(Color.white)
                  .clipShape(Capsule())
                  .overlay(
                    Capsule()
                      .stroke(focusedField == .email ? royalForestGreen : fieldBorderNormal, lineWidth: focusedField == .email ? 1.5 : 1)
                  )

                  HStack(spacing: 12) {
                    Image(systemName: "lock")
                      .font(.system(size: 15))
                      .foregroundColor(focusedField == .password ? royalForestGreen : subtitleMuted)
                      .frame(width: 20)

                    ZStack(alignment: .leading) {
                      if password.isEmpty {
                        Text(loc.t("auth.fields.password"))
                          .font(.system(size: 15))
                          .foregroundColor(placeholderGray)
                      }

                      if isPasswordVisible {
                        TextField("", text: $password)
                          .font(.system(size: 15))
                          .foregroundColor(titleCharcoal)
                          .focused($focusedField, equals: .password)
                          .autocapitalization(.none)
                      } else {
                        SecureField("", text: $password)
                          .font(.system(size: 15))
                          .foregroundColor(titleCharcoal)
                          .focused($focusedField, equals: .password)
                      }
                    }

                    Button {
                      isPasswordVisible.toggle()
                    } label: {
                      Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .font(.system(size: 15))
                        .foregroundColor(subtitleMuted)
                    }
                    .buttonStyle(.plain)
                  }
                  .padding(.horizontal, 18)
                  .padding(.vertical, 13)
                  .background(Color.white)
                  .clipShape(Capsule())
                  .overlay(
                    Capsule()
                      .stroke(focusedField == .password ? royalForestGreen : fieldBorderNormal, lineWidth: focusedField == .password ? 1.5 : 1)
                  )
                }

                // 错误提示
                if let errorMessage = auth.errorMessage {
                  HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                      .font(.system(size: 14))
                    Text(errorMessage)
                      .font(.system(size: 13))
                  }
                  .foregroundColor(Color(red: 0.82, green: 0.22, blue: 0.22))
                  .padding(.horizontal, 14)
                  .padding(.vertical, 10)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .background(Color(red: 0.99, green: 0.92, blue: 0.92))
                  .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // 5. 皇家墨绿操作主按钮
                Button(action: submit) {
                  ZStack {
                    if auth.isLoading {
                      ProgressView().tint(.white)
                    } else {
                      HStack(spacing: 8) {
                        Text(isRegistering ? loc.t("auth.buttons.signUp") : loc.t("auth.buttons.signIn"))
                          .font(.system(size: 16, weight: .semibold))
                        Image(systemName: isRegistering ? "sparkles" : "arrow.right")
                          .font(.system(size: 14, weight: .semibold))
                      }
                    }
                  }
                  .foregroundColor(.white)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 15)
                  .background(
                    isFormValid ? royalForestGreen : royalForestGreenDisabled
                  )
                  .clipShape(Capsule())
                  .shadow(
                    color: isFormValid ? royalForestGreen.opacity(0.35) : Color.clear,
                    radius: 12,
                    x: 0,
                    y: 5
                  )
                }
                .disabled(!isFormValid || auth.isLoading)
              }
              .padding(.horizontal, 22)
              .padding(.vertical, 22)
              .background(Color.white)
              .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
              .shadow(color: Color.black.opacity(0.08), radius: 24, x: 0, y: 10)
              .padding(.horizontal, 32) // 优雅内收黄金比例

              // 4. 条款移出卡片，下沉解耦（轻盈透气，与背景自然融合）
              VStack(spacing: 5) {
                Text(loc.t("auth.termsPrefix"))
                  .font(.system(size: 12))
                  .foregroundColor(subtitleMuted)

                HStack(spacing: 4) {
                  Button {
                    showingTerms = true
                  } label: {
                    Text(loc.t("legal.termsOfService"))
                      .font(.system(size: 12, weight: .medium))
                      .foregroundColor(royalForestGreen)
                      .underline()
                  }

                  Text(loc.t("auth.termsAnd"))
                    .font(.system(size: 12))
                    .foregroundColor(subtitleMuted)

                  Button {
                    showingPrivacy = true
                  } label: {
                    Text(loc.t("legal.privacyPolicy"))
                      .font(.system(size: 12, weight: .medium))
                      .foregroundColor(royalForestGreen)
                      .underline()
                  }
                }
              }
              .multilineTextAlignment(.center)
              .padding(.top, 20)
              .padding(.bottom, 24)
            }
          }

          Spacer(minLength: 12)

          // 5. 底部沉底工坊品质背书（Atelier Hallmark，完美平衡下部空白）
          HStack(spacing: 8) {
            Rectangle()
              .fill(goldAccent.opacity(0.35))
              .frame(width: 18, height: 0.8)

            Text("FLORAL ATELIER & STUDIO OS · EST. 2026")
              .font(.system(size: 10.5, weight: .semibold, design: .serif))
              .foregroundColor(subtitleMuted.opacity(0.85))
              .tracking(1.4)

            Rectangle()
              .fill(goldAccent.opacity(0.35))
              .frame(width: 18, height: 0.8)
          }
          .padding(.bottom, 16)
        }
      }
      .onTapGesture {
        hideKeyboard()
      }
      .sheet(isPresented: $showingTerms) {
        LegalDocumentView(documentType: .terms)
      }
      .sheet(isPresented: $showingPrivacy) {
        LegalDocumentView(documentType: .privacy)
      }
    }
  }

  private var isFormValid: Bool {
    !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
    !password.isEmpty &&
    (!isRegistering || !shopName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
  }

  private func submit() {
    hideKeyboard()
    HapticManager.shared.impact(style: .light)
    Task {
      if isRegistering {
        _ = await auth.register(email: email, password: password, shopName: shopName)
      } else {
        _ = await auth.login(email: email, password: password)
      }
    }
  }
}
