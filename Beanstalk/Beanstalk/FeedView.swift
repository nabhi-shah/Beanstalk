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
            
            ScrollViewReader { scrollProxy in
                ScrollView {
                    GeometryReader { proxy in
                        Color.clear.preference(key: ScrollOffsetKey.self, value: proxy.frame(in: .named("scroll")).minY)
                    }
                    .frame(height: 0)
                    
                    LazyVStack(spacing: 16) {
                        ForEach(MockData.articles) { article in
                            ArticleRowView(
                                article: article,
                                isExpanded: selectedArticle?.id == article.id,
                                onToggle: {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                        if selectedArticle?.id == article.id {
                                            selectedArticle = nil
                                        } else {
                                            selectedArticle = article
                                            // Scroll to top of the screen when expanded
                                            scrollProxy.scrollTo(article.id, anchor: .top)
                                        }
                                    }
                                }
                            )
                            .id(article.id)
                            .opacity(selectedArticle != nil && selectedArticle?.id != article.id ? 0 : 1)
                            .animation(.easeInOut(duration: 0.3), value: selectedArticle?.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 48)
                    .padding(.bottom, 120) // Space for TabBar
                }
                .scrollDisabled(selectedArticle != nil)
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
            }
            
            VStack {
                Spacer()
                ProgressiveBlurView(height: 140, edge: .bottom)
            }
            .ignoresSafeArea()
            .opacity(selectedArticle != nil ? 0 : 1)
            .animation(.easeInOut(duration: 0.3), value: selectedArticle?.id)

            ProgressiveBlurView(height: 120, edge: .top)
                .opacity(selectedArticle != nil ? 0 : 1)
                .animation(.easeInOut(duration: 0.3), value: selectedArticle?.id)

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
            .opacity(selectedArticle != nil ? 0 : 1)
            .animation(.easeInOut(duration: 0.3), value: selectedArticle?.id)
        }
    }
}

struct ArticleRowView: View {
    let article: Article
    var isExpanded: Bool = false
    var onToggle: () -> Void
    
    @State private var showActions: Bool = false
    @State private var isPressed: Bool = false
    @State private var touchLocation: CGPoint? = nil
    
    var body: some View {
        VStack(spacing: 12) {
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
            .modifier(RippleModifier(rippleColor: Color.black.opacity(0.4), touchLocation: touchLocation, isPressed: isPressed))
            .background(
                TouchLocatingView { location in
                    if !isPressed {
                        touchLocation = location
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 42, style: .continuous)
                    .stroke(Color(red: 223/255, green: 223/255, blue: 223/255), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            .frame(height: isExpanded ? expandedCardHeight : nil) // Expand to fill screen
            
            if isExpanded {
                // Pagination dots and chat icon
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(red: 40/255, green: 40/255, blue: 40/255))
                        .frame(width: 10, height: 10)
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 10, height: 10)
                    Image("chat-teardrop-dots-fill")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                        .frame(width: 10, height: 10)
                }
                .frame(height: 20)
                .transition(.opacity)
            }
        }
        .onChange(of: isExpanded) { oldValue, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeIn(duration: 0.2)) {
                        showActions = true
                    }
                }
            } else {
                showActions = false
            }
        }
    }
    
    // Computed height for expanded state to fill the screen minus safe areas, dots, and padding
    private var expandedCardHeight: CGFloat {
        let windowInsets = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets
        let safeTop = max(windowInsets?.top ?? 47, 47)
        let safeBottom = max(windowInsets?.bottom ?? 34, 34)
        // Screen height - safeTop - safeBottom - 20 (dots) - 12 (spacing)
        let calculated = UIScreen.main.bounds.height - safeTop - safeBottom - 32
        return max(calculated, 600) // Ensure it doesn't get ridiculously small on tiny screens
    }
    
    @ViewBuilder
    private func cardContent(image: Image?) -> some View {
        ZStack(alignment: .top) {
            // 2. Content
            ZStack(alignment: .top) {

                // Text Content
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
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
                        .lineLimit(isExpanded ? nil : 3)
                        .multilineTextAlignment(.leading)
                    
                    if isExpanded {
                        Text(article.aiSummary)
                            .font(.custom("InclusiveSans-Regular", size: 16))
                            .foregroundColor(.textSecondary)
                            .lineSpacing(4)
                            .padding(.top, 8)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .padding(.bottom, isExpanded ? 64 : 0) // Extra padding for buttons when expanded
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 240) // Shift content below the sharp image
            
            // 3. Action Buttons Overlay
            if isExpanded {
                VStack {
                    HStack {
                        Button(action: onToggle) {
                            Image("CaretLeft")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.textDark)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.white.opacity(0.01)))
                                .contentShape(Circle())
                        }
                        .buttonStyle(RippleButtonStyle(rippleColor: Color.black.opacity(0.3)))
                        .background(
                            Circle().glassEffect(.regular.tint(.white.opacity(0.25)), in: .circle)
                        )
                        
                        Spacer()
                        
                        Button(action: { }) {
                            Image("bookmark-simple")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.textDark)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.white.opacity(0.01)))
                                .contentShape(Circle())
                        }
                        .buttonStyle(RippleButtonStyle(rippleColor: Color.black.opacity(0.3)))
                        .background(
                            Circle().glassEffect(.regular.tint(.white.opacity(0.25)), in: .circle)
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        Button(action: {}) {
                            Image("PencilSimpleLine")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.textSecondary)
                                .frame(width: 56, height: 56)
                                .background(Circle().fill(Color.white.opacity(0.01)))
                                .contentShape(Circle())
                        }
                        .buttonStyle(RippleButtonStyle(rippleColor: Color.black.opacity(0.3)))
                        .background(
                            Circle().glassEffect(.regular.tint(.white.opacity(0.25)), in: .circle)
                        )
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .opacity(showActions ? 1 : 0)
            }
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
            } else {
                Color.clear.frame(height: 400)
            }
        }
        .background {
            // Full card background: #F5F5F5 base + blurred image on top
            ZStack {
                Color(red: 245/255, green: 245/255, blue: 245/255)
                
                if let image = image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .figmaLayerBlur(radius: 24)
                        .opacity(0.26)
                }
            }
        }
        .onTapGesture {
            if !isExpanded {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
                onToggle()
            }
        }
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
