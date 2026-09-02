import SwiftUI

struct OnboardingView: View {
    @Binding var appState: AppState
    var animationNamespace: Namespace.ID
    
    @State private var selectedPublications: Set<String> = []
    
    let publications = [
        "Financial Times", "Wall Street Journal", "Morning Brew", "NY Times",
        "CNBC", "Barron’s", "The Economist", "The Washington Post"
    ]
    
    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            if appState == .onboarding {
                Color.appBackground.ignoresSafeArea()
                    .transition(.opacity)
                
                // Logo that animates in
                Image("BeanstalkLogo")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 36)
                    .matchedGeometryEffect(id: "logo", in: animationNamespace)
                    .padding(.top, 40)
                    .transition(.identity)
                
                // Bottom Sheet
            VStack(spacing: 0) {
                Spacer().frame(height: 140) // Space for logo
                
                ZStack(alignment: .top) {
                    Color.white
                        .ignoresSafeArea(edges: .bottom)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            Spacer().frame(height: 100) // Space for sticky header
                            
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(publications, id: \.self) { pub in
                                    PublicationCard(
                                        title: pub,
                                        isSelected: selectedPublications.contains(pub)
                                    ) {
                                        toggleSelection(for: pub)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 160) // Space for bottom nav
                        }
                    }
                    
                    // Sticky Header with Progressive Blur
                    ZStack(alignment: .top) {
                        ProgressiveBlurView(height: 80, edge: .top)
                        
                        VStack(spacing: 4) {
                            Text("What would you like to follow?")
                                .font(.custom("InclusiveSans-Regular", size: 20))
                                .foregroundColor(.textDark)
                        }
                        .padding(.top, 40)
                    }
                    
                    // Bottom Nav
                    VStack {
                        Spacer()
                        ZStack(alignment: .bottom) {
                            ProgressiveBlurView(height: 80, edge: .bottom)
                            
                            OnboardingBottomNav(
                                isNextEnabled: !selectedPublications.isEmpty,
                                onBack: {
                                    appState = .login
                                },
                                onNext: {
                                    // Let the ripple effect play for 0.4s
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                        appState = .loading
                                    }
                                }
                            )
                        }
                    }
                    .ignoresSafeArea(edges: .bottom)
                }
                .cornerRadius(48, corners: [.topLeft, .topRight])
                .shadow(color: Color.black.opacity(0.18), radius: 37.5, x: 0, y: 15)
            }
            .transition(.move(edge: .bottom))
            .ignoresSafeArea(edges: .bottom)
            }
        }
    }
    
    private func toggleSelection(for pub: String) {
        if selectedPublications.contains(pub) {
            selectedPublications.remove(pub)
        } else {
            selectedPublications.insert(pub)
        }
    }
}

// Extension to apply corner radius to specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
