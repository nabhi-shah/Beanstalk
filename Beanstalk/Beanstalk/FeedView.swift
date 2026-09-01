import SwiftUI
import Combine

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
                    .padding(.horizontal, selectedArticle != nil ? 20 : 12)
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
    
    @State private var frontCardIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isLongPressing: Bool = false
    
    private func cardMetrics(for index: Int) -> (zIndex: Double, scaleX: CGFloat, scaleY: CGFloat, xOffset: CGFloat, opacity: Double) {
        let isFront = index == frontCardIndex
        let isSecond = index == (frontCardIndex + 1) % 3
        
        var sX: CGFloat = 1.0
        var sY: CGFloat = 1.0
        var xOff: CGFloat = 0
        var op: Double = 1.0
        
        if isFront {
            sX = 1.0
            sY = 1.0
            xOff = dragOffset
            op = 1.0
        } else if isSecond {
            sX = 1.0
            sY = 0.95
            xOff = showActions ? 7 : 0
            op = isExpanded ? (showActions ? 1 : 0) : 0
        } else {
            sX = 1.0
            sY = 0.90
            xOff = showActions ? 14 : 0
            op = isExpanded ? (showActions ? 1 : 0) : 0
        }
        
        if isExpanded && isLongPressing && isFront {
            sX *= 1.05
            sY *= 1.05
        }
        
        if isFront {
            return (zIndex: 2, scaleX: sX, scaleY: sY, xOffset: xOff, opacity: op)
        } else if isSecond {
            return (zIndex: 1, scaleX: sX, scaleY: sY, xOffset: xOff, opacity: op)
        } else {
            return (zIndex: 0, scaleX: sX, scaleY: sY, xOffset: xOff, opacity: op)
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Card 2
                let c2 = cardMetrics(for: 2)
                RoundedRectangle(cornerRadius: 42, style: .continuous)
                    .fill(Color(red: 205/255, green: 205/255, blue: 205/255))
                    .overlay(RoundedRectangle(cornerRadius: 42, style: .continuous).stroke(Color(red: 223/255, green: 223/255, blue: 223/255), lineWidth: 0.5))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .overlay(
                        Group {
                            if isExpanded {
                                grabHandle()
                            }
                        }
                    )
                    .scaleEffect(x: c2.scaleX, y: c2.scaleY)
                    .offset(x: c2.xOffset)
                    .opacity(c2.opacity)
                    .zIndex(c2.zIndex)
                    .layoutPriority(-1)
                
                // Card 1
                let c1 = cardMetrics(for: 1)
                Group {
                    if let url = article.thumbnailURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image): articleDetailCard(image: image)
                            case .empty, .failure: articleDetailCard(image: nil)
                            @unknown default: articleDetailCard(image: nil)
                            }
                        }
                    } else {
                        articleDetailCard(image: nil)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                .overlay(
                    Color.white.opacity(0.01)
                        .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                        .modifier(RippleModifier(rippleColor: Color.black.opacity(0.4), touchLocation: touchLocation, isPressed: isPressed && frontCardIndex == 1))
                        .allowsHitTesting(false)
                )
                .background(
                    TouchLocatingView { location in
                        if !isPressed && frontCardIndex == 1 {
                            touchLocation = location
                        }
                    }
                )
                .overlay(RoundedRectangle(cornerRadius: 42, style: .continuous).stroke(Color(red: 223/255, green: 223/255, blue: 223/255), lineWidth: 0.5))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                .scaleEffect(x: c1.scaleX, y: c1.scaleY)
                .offset(x: c1.xOffset)
                .opacity(c1.opacity)
                .zIndex(c1.zIndex)
                .layoutPriority(-1)
                
                // Card 0 (Main Card)
                let c0 = cardMetrics(for: 0)
                Group {
                    if let url = article.thumbnailURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image): cardContent(image: image)
                            case .empty, .failure: cardContent(image: nil)
                            @unknown default: cardContent(image: nil)
                            }
                        }
                    } else {
                        cardContent(image: nil)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                .overlay(
                    Color.white.opacity(0.01)
                        .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                        .modifier(RippleModifier(rippleColor: Color.black.opacity(0.4), touchLocation: touchLocation, isPressed: isPressed && frontCardIndex == 0))
                        .allowsHitTesting(false)
                )
                .background(
                    TouchLocatingView { location in
                        if !isPressed && frontCardIndex == 0 {
                            touchLocation = location
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 42, style: .continuous)
                        .stroke(Color(red: 223/255, green: 223/255, blue: 223/255), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                .scaleEffect(x: c0.scaleX, y: c0.scaleY)
                .offset(x: c0.xOffset)
                .opacity(c0.opacity)
                .zIndex(c0.zIndex)
            }

            .frame(height: isExpanded ? expandedCardHeight : nil) // Expand to fill screen
            
            if isExpanded {
                // Pagination dots and chat icon
                HStack(spacing: 4) {
                    Circle()
                        .fill(frontCardIndex == 0 ? Color(red: 40/255, green: 40/255, blue: 40/255) : Color.gray)
                        .frame(width: 12, height: 12)
                    Circle()
                        .fill(frontCardIndex == 1 ? Color(red: 40/255, green: 40/255, blue: 40/255) : Color.gray)
                        .frame(width: 12, height: 12)
                    Image("chat-teardrop-dots-fill")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(frontCardIndex == 2 ? Color(red: 40/255, green: 40/255, blue: 40/255) : Color.gray)
                        .frame(width: 12, height: 12)
                }
                .frame(height: 20)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: frontCardIndex)
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
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    frontCardIndex = 0
                }
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
    private func articleDetailCard(image: Image?) -> some View {
        ZStack(alignment: .top) {
            // Main scrollable content
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Spacer to clear the fixed header area
                    Spacer()
                        .frame(height: 120)
                    
                    // Publication & Author
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
                                .bold()
                            
                            if !article.author.isEmpty {
                                Text(article.author)
                                    .font(.custom("InclusiveSans-Regular", size: 14))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Title
                    Text(article.title)
                        .font(.custom("InclusiveSans-Regular", size: 18))
                        .foregroundColor(.textDark)
                        .bold()
                        .padding(.horizontal, 24)
                    
                    // Article Content
                    Text(article.content)
                        .font(.custom("InclusiveSans-Regular", size: 16))
                        .foregroundColor(.textSecondary)
                        .lineSpacing(4)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 120) // Space for FAB and dots
                }
                .padding(.top, 16)
            }
            
            // Fixed Header overlay (sits above ScrollView)
            ZStack(alignment: .top) {
                // Progressive blur behind the header to fade the scrolling text
                ProgressiveBlurView(height: 140, edge: .top)
                    .allowsHitTesting(false)
                
                // Sharp Thumbnail Image
                if let image = image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                }
                
                // Action Buttons Overlay
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
            }
            
            // Floating Action Button (FAB)
            VStack {
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
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
            
            // Bottom Grab Handle for Swiping Cards (only when expanded)
            if isExpanded {
                grabHandle()
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
            
            // Bottom Grab Handle for Swiping Cards (below buttons in Z-index)
            if isExpanded {
                grabHandle()
            }
            
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
                    .progressiveBleedBlur(radius: 24, offset: 0.75, direction: .bottom, steps: 7)
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
    
    @ViewBuilder
    private func grabHandle() -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            ZStack(alignment: .bottom) {
                // Progressive blur behind the grabber
                ProgressiveBlurView(height: 64, edge: .bottom)
                    .allowsHitTesting(false)
                
                VStack(spacing: 8) {
                    VStack(spacing: 3) {
                        HStack(spacing: 3) {
                            Circle().frame(width: 3, height: 3)
                            Circle().frame(width: 3, height: 3)
                        }
                        HStack(spacing: 3) {
                            Circle().frame(width: 3, height: 3)
                            Circle().frame(width: 3, height: 3)
                        }
                        HStack(spacing: 3) {
                            Circle().frame(width: 3, height: 3)
                            Circle().frame(width: 3, height: 3)
                        }
                    }
                    .foregroundColor(Color.textSecondary.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(Color.white.opacity(0.001))
                .contentShape(Rectangle())
                .overlay(carouselGestureLayer()) // Gesture is now ONLY at the bottom
            }
        }
    }
    
    @ViewBuilder
    private func carouselGestureLayer() -> some View {
        Color.white.opacity(0.001)
            .conditionalGesture(true, 
                // Use minimumDistance 15 so it doesn't block vertical scrolling on ScrollViews
                DragGesture(minimumDistance: 15)
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            isLongPressing = false
                            if dragOffset > 50 {
                                frontCardIndex = (frontCardIndex - 1 + 3) % 3
                            } else if dragOffset < -50 {
                                frontCardIndex = (frontCardIndex + 1) % 3
                            }
                            dragOffset = 0
                        }
                    }
            )
            .onLongPressGesture(minimumDuration: 0, pressing: { isPressing in
                if isPressing {
                    withAnimation(.spring(response: 0.05, dampingFraction: 0.6)) {
                        isLongPressing = true
                    }
                    isPressed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPressed = false
                    }
                } else if !isPressing && dragOffset == 0 {
                    // Only revert if we haven't started dragging
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        isLongPressing = false
                    }
                }
            }, perform: {})
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
    
    @ViewBuilder
    func conditionalGesture<G: Gesture>(_ condition: Bool, _ gesture: G) -> some View {
        if condition {
            self.gesture(gesture)
        } else {
            self
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace
    FeedView(appState: .constant(.feed), animationNamespace: namespace)
}
import SwiftUI
