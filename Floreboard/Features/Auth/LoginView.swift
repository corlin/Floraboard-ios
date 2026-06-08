import SwiftUI

struct LoginView: View {
  @EnvironmentObject var auth: AuthService
  @State private var storeName = ""
  @State private var password = ""
  @State private var isRegistering = false

  var body: some View {
    ZStack {
      AppTheme.premiumGradient.ignoresSafeArea()

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
          TextField(Tx.t("login.storeName"), text: $storeName)
            .padding()
            .background(AppTheme.surfaceElevated)
            .cornerRadius(AppTheme.controlRadius)
            .overlay(RoundedRectangle(cornerRadius: AppTheme.controlRadius).stroke(AppTheme.hairline, lineWidth: 1))
            .autocapitalization(.none)

          SecureField("Password", text: $password)
            .padding()
            .background(AppTheme.surfaceElevated)
            .cornerRadius(AppTheme.controlRadius)
            .overlay(RoundedRectangle(cornerRadius: AppTheme.controlRadius).stroke(AppTheme.hairline, lineWidth: 1))

          Button(action: submit) {
            if auth.isLoading {
              ProgressView().tint(AppTheme.iconOnAccent)
            } else {
              Text(isRegistering ? "Create Account" : Tx.t("login.enter"))
                .font(AppTheme.sansFont(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding()
            }
          }
          .buttonStyle(PrimaryButtonStyle())
          .disabled(storeName.isEmpty || password.isEmpty || auth.isLoading)
          
          Button(action: {
            withAnimation {
              isRegistering.toggle()
              auth.errorMessage = nil
            }
          }) {
            Text(isRegistering ? "Already have an account? Login" : "Don't have an account? Register")
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
    Task {
      if isRegistering {
        _ = await auth.register(storeName: storeName, password: password)
      } else {
        _ = await auth.login(storeName: storeName, password: password)
      }
    }
  }
}
