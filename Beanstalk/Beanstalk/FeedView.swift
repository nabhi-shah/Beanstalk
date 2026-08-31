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
    @State private var selectedArticle: Article?
    @Namespace private var heroAnimation
    
    var body: some View {
        NavigationStack {
            UnionTabView(
                selection: $selectedTab, 
                tabs: [.home, .search, .saved, .profile], 
                minimizeProgress: minimizeProgress,
                hideOffset: selectedArticle != nil ? 100 : 0
            ) {
                FeedContentView(animationNamespace: animationNamespace, minimizeProgress: $minimizeProgress, selectedArticle: $selectedArticle, heroAnimation: heroAnimation).unionTab(MainTab.home)
                
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
        .overlay(
            Group {
                if let selectedArticle = selectedArticle {
                    ArticleDetailView(article: selectedArticle, animation: heroAnimation, selectedArticle: $selectedArticle)
                        .zIndex(100)
                        .transition(.identity) // Rely on matchedGeometryEffect
                }
            }
        )
    }
}

struct FeedContentView: View {
    var animationNamespace: Namespace.ID
    @Binding var minimizeProgress: Double
    @Binding var selectedArticle: Article?
    var heroAnimation: Namespace.ID
    
    @State private var lastOffset: CGFloat = 0

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
                        .opacity(selectedArticle != nil ? 0 : 1)
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
        .matchedGeometryEffect(id: "card-\(article.id)", in: animation, isSource: !isExpanded)
    }
    
    @ViewBuilder
    private func cardContent(image: Image?) -> some View {
        ZStack(alignment: .top) {
            
          
                
            
            // 2. Content
            ZStack(alignment: .top) {
                // Blurred Image Layer as a separate element, NOT clipped!
                GeometryReader { proxy in
                    if let image = image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            // 1. Frame it exactly to the text container
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            // 2. Clip it so it has a HARD edge exactly at the seam line
                            
                            // 3. Apply the un-clamped blur. The blur will take that hard edge at the seam 
                            // and organically bleed it upwards by 25 points into the top photo!
                            .clipped()
                            .figmaLayerBlur(radius: 94)
                            .opacity(0.40)
                    }
                }
                .allowsHitTesting(false)
                
                // Text Content
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
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 240) // Shift content below the sharp image
        }
        .background(alignment: .top) {
            if let image = image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 290)
                    .clipped()
                    .progressiveBleedBlur(radius: 24, offset: 0.75, direction: .bottom, steps: 5)
                    .matchedGeometryEffect(id: "background-\(article.id)", in: animation, isSource: !isExpanded)
            } else {
                Color.clear.frame(height: 400)
                    .matchedGeometryEffect(id: "background-\(article.id)", in: animation, isSource: !isExpanded)
            }
        }
        .background(Color(red: 245/255, green: 245/255, blue: 245/255))
    }
}

// Custom modifier to simulate Figma's un-clamped layer blur
struct FigmaLayerBlur: ViewModifier {
    var radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .padding(radius * 2)
            .blur(radius: radius)
            .padding(-radius * 2)
    }
}

extension View {
    func figmaLayerBlur(radius: CGFloat) -> some View {
        modifier(FigmaLayerBlur(radius: radius))
    }
}

#Preview {
    @Previewable @Namespace var namespace
    FeedView(appState: .constant(.feed), animationNamespace: namespace)
}
import SwiftUI
