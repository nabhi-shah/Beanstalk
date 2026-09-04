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
    @State private var selectedArticle: Article? = nil
    @State private var selectedTab: MainTab = .home
    @Namespace private var animationNamespace

    var body: some View {
        ZStack(alignment: .top) {
            if appState == .login {
                ContentView(appState: $appState, animationNamespace: animationNamespace)
                    .transition(.opacity)
                    .zIndex(0)
            }
            
            OnboardingView(appState: $appState, animationNamespace: animationNamespace)
                .zIndex(1)
                .allowsHitTesting(appState == .onboarding)
            
            FeedView(appState: $appState, selectedArticle: $selectedArticle, selectedTab: $selectedTab, animationNamespace: animationNamespace)
                .zIndex(2)
                .allowsHitTesting(appState == .feed)
            
            LoadingView(appState: $appState, animationNamespace: animationNamespace)
                .zIndex(3)
                .allowsHitTesting(appState == .loading)
            
            if appState == .onboarding || appState == .loading || appState == .feed {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Image("BeanstalkLogo")
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .frame(height: appState == .feed ? 24 : 36)
                            .matchedGeometryEffect(id: "logo", in: animationNamespace)
                        Spacer()
                    }
                    .padding(.top, appState == .feed ? 4 : 40)
                    .padding(.bottom, appState == .feed ? 8 : 0)
                    
                    Spacer()
                }
                .opacity((selectedArticle != nil || (appState == .feed && selectedTab != .home)) ? 0 : 1)
                .animation(.easeInOut(duration: 0.3), value: (selectedArticle != nil || (appState == .feed && selectedTab != .home)))
                .zIndex(100)
                .allowsHitTesting(false)
            }
        }
        .animation(.spring(response: 0.7, dampingFraction: 0.8), value: appState)
    }
}

#Preview {
    MainCoordinator()
}
