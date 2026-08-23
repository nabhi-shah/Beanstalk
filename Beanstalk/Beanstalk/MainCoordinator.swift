import SwiftUI

enum AppState {
    case login
    case onboarding
    case feed
}

struct MainCoordinator: View {
    @State private var appState: AppState = .login
    @Namespace private var animationNamespace

    var body: some View {
        ZStack {
            if appState == .login {
                ContentView(appState: $appState, animationNamespace: animationNamespace)
                    .transition(.opacity)
                    .zIndex(0)
            }
            
            OnboardingView(appState: $appState, animationNamespace: animationNamespace)
                .zIndex(1)
                .allowsHitTesting(appState == .onboarding || appState == .feed)
            
            if appState == .feed {
                FeedView(appState: $appState, animationNamespace: animationNamespace)
                    .transition(.move(edge: .trailing))
                    .zIndex(2)
            }
        }
        .animation(.spring(response: 0.7, dampingFraction: 0.8), value: appState)
    }
}

#Preview {
    MainCoordinator()
}
