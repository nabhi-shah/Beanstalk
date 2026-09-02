with open("Beanstalk/Beanstalk/MainCoordinator.swift", "r") as f:
    content = f.read()

# Add loading state
content = content.replace("case onboarding\n    case feed", "case onboarding\n    case loading\n    case feed")

# Add LoadingView
loading_view = """
struct LoadingView: View {
    @Binding var appState: AppState
    var animationNamespace: Namespace.ID
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.appBackground.ignoresSafeArea()
            
            Image("BeanstalkLogo")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(height: 36)
                .matchedGeometryEffect(id: "logo", in: animationNamespace)
                .padding(.top, 40)
            
            VStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .brandGreen))
                    .scaleEffect(1.5)
                Spacer()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                appState = .feed
            }
        }
    }
}
"""

content = content.replace("struct MainCoordinator", loading_view + "\nstruct MainCoordinator")

# Add to MainCoordinator body
coordinator_body_old = """            if appState == .feed {
                FeedView(appState: $appState, animationNamespace: animationNamespace)
                    .transition(.move(edge: .trailing))
                    .zIndex(2)
            }"""

coordinator_body_new = """            if appState == .loading {
                LoadingView(appState: $appState, animationNamespace: animationNamespace)
                    .transition(.opacity)
                    .zIndex(2)
            }
            
            if appState == .feed {
                FeedView(appState: $appState, animationNamespace: animationNamespace)
                    .transition(.opacity)
                    .zIndex(3)
            }"""

content = content.replace(coordinator_body_old, coordinator_body_new)

with open("Beanstalk/Beanstalk/MainCoordinator.swift", "w") as f:
    f.write(content)

