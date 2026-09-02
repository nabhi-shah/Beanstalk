import SwiftUI

enum AppState {
    case login
    case onboarding
    case loading
    case feed
}


struct LoadingView: View {
    @Binding var appState: AppState
    var animationNamespace: Namespace.ID
    
    var body: some View {
        ZStack(alignment: .top) {
            if appState == .loading {
                Color.appBackground.ignoresSafeArea()
                    .transition(.opacity)
                
                Image("BeanstalkLogo")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 36)
                    .matchedGeometryEffect(id: "logo", in: animationNamespace)
                    .padding(.top, 40)
                    .transition(.identity)
                
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .brandGreen))
                        .scaleEffect(1.5)
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .onChange(of: appState) { _, newValue in
            if newValue == .loading {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if appState == .loading {
                        withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                            appState = .feed
                        }
                    }
                }
            }
        }
    }
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
                .allowsHitTesting(appState == .onboarding)
            
            LoadingView(appState: $appState, animationNamespace: animationNamespace)
                .zIndex(2)
                .allowsHitTesting(appState == .loading)
            
            if appState == .feed {
                FeedView(appState: $appState, animationNamespace: animationNamespace)
                    .transition(.opacity)
                    .zIndex(3)
            }
        }
        .animation(.spring(response: 0.7, dampingFraction: 0.8), value: appState)
    }
}

#Preview {
    MainCoordinator()
}
