import SwiftUI
import Combine
import Glur

enum MainTab: Hashable {
    case home, search, saved, profile
}
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct FeedView: View {
    @Binding var appState: AppState
    var animationNamespace: Namespace.ID
    
    @State private var selectedTab: MainTab = .home
    @State private var minimizeProgress: Double = 0
    
    var body: some View {
        NavigationStack {
            UnionTabView(selection: $selectedTab, tabs: [.home, .search, .saved, .profile], minimizeProgress: minimizeProgress) {
                FeedContentView(animationNamespace: animationNamespace, minimizeProgress: $minimizeProgress).unionTab(MainTab.home)
                
                Color.appBackground.ignoresSafeArea()
                    .overlay(Text("Search").foregroundColor(.textSecondary))
                    .unionTab(MainTab.search)
                
                Color.appBackground.ignoresSafeArea()
                    .overlay(Text("Saved").foregroundColor(.textSecondary))
                    .unionTab(MainTab.saved)
                
                Color.appBackground.ignoresSafeArea()
                    .overlay(Text("Profile").foregroundColor(.textSecondary))
                    .unionTab(MainTab.profile)
            } item: { tab, isSelected in
                let iconName: String = {
                    switch tab {
                    case .home: return "cards-three"
                    case .search: return "magnifying-glass"
                    case .saved: return "bookmark"
                    case .profile: return "user-circle"
                    }
                }()
                
                ZStack {
                    Image(iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.textSecondary)
                        .opacity(isSelected ? 0 : 1)
                    
                    Image("\(iconName)-fill")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                        .opacity(isSelected ? 1 : 0)
                }
                .frame(width: 28, height: 28)
                .animation(.easeInOut(duration: 0.15), value: isSelected)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(.brandGreen)
    }
}

struct FeedContentView: View {
    var animationNamespace: Namespace.ID
    @Binding var minimizeProgress: Double
    @State private var lastOffset: CGFloat = 0
    @State private var selectedArticle: Article?
    @Namespace private var heroAnimation

    var body: some View {
        ZStack(alignment: .top) {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView {
                GeometryReader { proxy in
                    Color.clear.preference(key: ScrollOffsetKey.self, value: proxy.frame(in: .named("scroll")).minY)
                }
                .frame(height: 0)
                
                LazyVStack(spacing: 16) {
                    ForEach(MockData.articles) { article in
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                selectedArticle = article
                            }
                        }) {
                            ArticleRowView(article: article, animation: heroAnimation, isExpanded: selectedArticle?.id == article.id)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .opacity(selectedArticle?.id == article.id ? 0 : 1)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 64)
                .padding(.bottom, 120) // Space for TabBar
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { offset in
                let delta = lastOffset - offset
                lastOffset = offset
                
                if offset >= 0 {
                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                        minimizeProgress = 0
                    }
                } else {
                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                        let newProgress = minimizeProgress + Double(delta / 100.0)
                        minimizeProgress = min(max(newProgress, 0), 1)
                    }
                }
            }
            
            VStack {
                Spacer()
                ProgressiveBlurView(height: 140, edge: .bottom)
            }
            .ignoresSafeArea()

            ProgressiveBlurView(height: 120, edge: .top)

            // Custom Header
            HStack {
                Spacer()
                Image("BeanstalkLogo")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
                    .matchedGeometryEffect(id: "logo", in: animationNamespace)
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                Spacer()
            }
        }
        .overlay(
            Group {
                if let selectedArticle = selectedArticle {
                    ArticleDetailView(article: selectedArticle, animation: heroAnimation, selectedArticle: $selectedArticle)
                        .zIndex(100)
                        .transition(.identity) // We rely on matchedGeometryEffect for transitions
                }
            }
        )
    }
}

struct ArticleRowView: View {
    let article: Article
    var animation: Namespace.ID
    var isExpanded: Bool = false
    
    var body: some View {
        Group {
            if let url = article.thumbnailURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        cardContent(image: image)
                    case .empty, .failure:
                        cardContent(image: nil)
                    @unknown default:
                        cardContent(image: nil)
                    }
                }
            } else {
                cardContent(image: nil)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .stroke(Color(red: 223/255, green: 223/255, blue: 223/255), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .matchedGeometryEffect(id: "card-\(article.id)", in: animation)
    }
    
    @ViewBuilder
    private func cardContent(image: Image?) -> some View {
        ZStack(alignment: .bottom) {
            // Background Image
            Color.clear
                .overlay(
                    GeometryReader { proxy in
                        if let image = image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: proxy.size.width, height: proxy.size.height)
                                .clipped()
                                .glur(radius: 24.0, offset: 0.72, interpolation: 0.28, direction: .down)
                        } else {
                            Color(red: 245/255, green: 245/255, blue: 245/255) // #F5F5F5
                        }
                    }
                )
                .matchedGeometryEffect(id: "background-\(article.id)", in: animation)
            
            // Content Section
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    // Publication Logo
                    Image(article.publication)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(article.publication)
                            .font(.custom("InclusiveSans-Regular", size: 16))
                            .foregroundColor(.textDark)
                        
                        if !article.author.isEmpty {
                            Text(article.author)
                                .font(.custom("InclusiveSans-Regular", size: 14))
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                
                Text(article.title)
                    .font(.custom("InclusiveSans-Regular", size: 18))
                    .foregroundColor(.textDark)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(24)
            .padding(.top, 48) // Extra padding to allow the gradient to fade in above the text
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: Color(red: 245/255, green: 245/255, blue: 245/255).opacity(0.74), location: 0.4),
                        .init(color: Color(red: 245/255, green: 245/255, blue: 245/255).opacity(0.74), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .frame(minHeight: 420)
    }
}

#Preview {
    @Previewable @Namespace var namespace
    FeedView(appState: .constant(.feed), animationNamespace: namespace)
}
import SwiftUI
