import SwiftUI

enum AppState {
    case login
    case onboarding
}

struct MainCoordinator: View {
    @State private var appState: AppState = .login
    @Namespace private var animationNamespace

    var body: some View {
        ZStack {
            if appState == .login {
                ContentView(appState: $appState, animationNamespace: animationNamespace)
            } else if appState == .onboarding {
                OnboardingView(appState: $appState, animationNamespace: animationNamespace)
            }
        }
        .animation(.spring(response: 0.7, dampingFraction: 0.8), value: appState)
    }
}

#Preview {
    MainCoordinator()
}
