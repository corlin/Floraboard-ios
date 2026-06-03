import SwiftUI

struct LoginView: View {
  @EnvironmentObject var auth: AuthService
  @State private var storeName = ""
  @State private var password = ""

  var body: some View {
    ZStack {
      AppTheme.premiumGradient.ignoresSafeArea()

      VStack(spacing: 30) {
        Image(systemName: "leaf.fill")  // Replaced flower.fill
          .resizable()
          .scaledToFit()
          .frame(width: 80, height: 80)
          .foregroundStyle(AppTheme.primary)
          .padding()
          .background(AppTheme.surfaceGlass)
          .clipShape(Circle())
          .shadow(color: AppTheme.primary.opacity(0.3), radius: 10, x: 0, y: 5)

        Text("Floreboard")
          .font(AppTheme.serifFont(size: 40, weight: .bold))
          .foregroundColor(AppTheme.foreground)

        VStack(spacing: 16) {
          TextField(Tx.t("login.storeName"), text: $storeName)
            .padding()
            .background(AppTheme.surfaceElevated)
            .cornerRadius(AppTheme.controlRadius)
            .overlay(RoundedRectangle(cornerRadius: AppTheme.controlRadius).stroke(AppTheme.hairline, lineWidth: 1))

          SecureField("Password", text: $password)
            .padding()
            .background(AppTheme.surfaceElevated)
            .cornerRadius(AppTheme.controlRadius)
            .overlay(RoundedRectangle(cornerRadius: AppTheme.controlRadius).stroke(AppTheme.hairline, lineWidth: 1))

          Button(action: login) {
            if auth.isLoading {
              ProgressView().tint(AppTheme.iconOnAccent)
            } else {
              Text(Tx.t("login.enter"))
                .font(AppTheme.sansFont(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding()
            }
          }
          .buttonStyle(PrimaryButtonStyle())
          .disabled(storeName.isEmpty || password.isEmpty || auth.isLoading)

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

  func login() {
    Task {
      _ = await auth.login(storeName: storeName, password: password)
    }
  }
}
