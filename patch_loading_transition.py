with open("Beanstalk/Beanstalk/MainCoordinator.swift", "r") as f:
    content = f.read()

old_loading_call = """            if appState == .loading {
                LoadingView(appState: $appState, animationNamespace: animationNamespace)
                    .transition(.opacity)
                    .zIndex(2)
            }"""

new_loading_call = """            LoadingView(appState: $appState, animationNamespace: animationNamespace)
                .zIndex(2)
                .allowsHitTesting(appState == .loading)"""

content = content.replace(old_loading_call, new_loading_call)

old_loading_view = """struct LoadingView: View {
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
}"""

new_loading_view = """struct LoadingView: View {
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
                        appState = .feed
                    }
                }
            }
        }
    }
}"""

content = content.replace(old_loading_view, new_loading_view)

with open("Beanstalk/Beanstalk/MainCoordinator.swift", "w") as f:
    f.write(content)

