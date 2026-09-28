import SwiftUI

struct LoginView: View {
  @EnvironmentObject var auth: AuthService
  @State private var email = ""
  @State private var password = ""
  @State private var shopName = ""
  @State private var isRegistering = false

  var body: some View {
    ZStack {
      PremiumBackgroundView()

      VStack(spacing: 30) {
        Image("LoginIllustration")
          .resizable()
          .scaledToFit()
          .frame(width: 140, height: 140)
          .clipShape(Circle())
          .overlay(Circle().stroke(AppTheme.hairline, lineWidth: 1))
          .shadow(color: AppTheme.shadow, radius: 12, x: 0, y: 6)
          .padding(.bottom, -10)

        Text("Floreboard")
          .font(AppTheme.serifFont(size: 40, weight: .bold))
          .foregroundColor(AppTheme.foreground)

        VStack(spacing: 16) {
          if isRegistering {
            TextField(Tx.t("login.storeName"), text: $shopName)
              .padding()
              .background(AppTheme.surfaceElevated)
              .cornerRadius(AppTheme.controlRadius)
              .overlay(RoundedRectangle(cornerRadius: AppTheme.controlRadius).stroke(AppTheme.hairline, lineWidth: 1))
              .autocapitalization(.words)
          }

          TextField(Tx.t("login.email"), text: $email)
            .padding()
            .background(AppTheme.surfaceElevated)
            .cornerRadius(AppTheme.controlRadius)
            .overlay(RoundedRectangle(cornerRadius: AppTheme.controlRadius).stroke(AppTheme.hairline, lineWidth: 1))
            .autocapitalization(.none)

          SecureField(Tx.t("login.password"), text: $password)
            .padding()
            .background(AppTheme.surfaceElevated)
            .cornerRadius(AppTheme.controlRadius)
            .overlay(RoundedRectangle(cornerRadius: AppTheme.controlRadius).stroke(AppTheme.hairline, lineWidth: 1))

          Button(action: submit) {
            if auth.isLoading {
              ProgressView().tint(AppTheme.iconOnAccent)
            } else {
              Text(isRegistering ? Tx.t("login.createAccount") : Tx.t("login.enter"))
                .font(AppTheme.sansFont(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding()
            }
          }
          .buttonStyle(PrimaryButtonStyle())
          .disabled(email.isEmpty || password.isEmpty || (isRegistering && shopName.isEmpty) || auth.isLoading)

          Button(action: {
            withAnimation {
              isRegistering.toggle()
              auth.errorMessage = nil
            }
          }) {
            Text(isRegistering ? Tx.t("login.hasAccount") : Tx.t("login.noAccount"))
              .font(AppTheme.sansFont(size: 14, weight: .medium))
              .foregroundColor(AppTheme.primary)
          }
          .padding(.top, 4)

          if let errorMessage = auth.errorMessage {
            Text(errorMessage)
              .font(AppTheme.sansFont(size: 14))
              .foregroundColor(AppTheme.danger)
              .multilineTextAlignment(.center)
              .padding(.top, 4)
          }
        }
        .padding(30)
        .glassmorphic()
        .padding(.horizontal)
      }
    }
    .onTapGesture {
      hideKeyboard()
    }
  }

  func submit() {
    hideKeyboard()
    Task {
      if isRegistering {
        _ = await auth.register(email: email, password: password, shopName: shopName)
      } else {
        _ = await auth.login(email: email, password: password)
      }
    }
  }
}
