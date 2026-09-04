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
    @Binding var selectedArticle: Article?
    @Binding var selectedTab: MainTab
    var animationNamespace: Namespace.ID
    
    @State private var minimizeProgress: Double = 0
    @Namespace private var heroAnimation
    
    init(appState: Binding<AppState>, selectedArticle: Binding<Article?>? = nil, selectedTab: Binding<MainTab>? = nil, animationNamespace: Namespace.ID) {
        self._appState = appState
        self._selectedArticle = selectedArticle ?? .constant(nil)
        self._selectedTab = selectedTab ?? .constant(.home)
        self.animationNamespace = animationNamespace
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            if appState == .feed {
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
                
                SavedView()
                    .unionTab(MainTab.saved)
                
                Color.appBackground.ignoresSafeArea()
                    .overlay(Text("Profile").foregroundColor(.textSecondary))
                    .unionTab(MainTab.profile)
            } item: { tab, isSelected in
                let iconName: String = {
                    switch tab {
                    case .home: return "cards-three"
                    case .search: return "magnifying-glass"
                    case .saved: return "Bookmarks"
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
            .transition(.opacity)
            .tint(.brandGreen)
            }
        }
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
    @State private var showChevrons: Bool = false
    @State private var chatInputText: String = ""
    @State private var isAnnotationModeActive: Bool = false
    
    private func cardMetrics(for index: Int) -> (zIndex: Double, scaleX: CGFloat, scaleY: CGFloat, xOffset: CGFloat, opacity: Double) {
        if !isExpanded {
            if frontCardIndex != 0 {
                if index == frontCardIndex {
                    return (zIndex: 2, scaleX: 1.0, scaleY: 1.0, xOffset: UIScreen.main.bounds.width, opacity: 1.0)
                } else if index == 0 {
                    return (zIndex: 1, scaleX: 1.0, scaleY: 1.0, xOffset: 0, opacity: 1.0)
                } else {
                    return (zIndex: 0, scaleX: 1.0, scaleY: 1.0, xOffset: 0, opacity: 0.0)
                }
            } else {
                if index == 0 {
                    return (zIndex: 2, scaleX: 1.0, scaleY: 1.0, xOffset: 0, opacity: 1.0)
                } else {
                    return (zIndex: 0, scaleX: 1.0, scaleY: 1.0, xOffset: 0, opacity: 0.0)
                }
            }
        }
        
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
                Group {
                    if let url = article.thumbnailURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image): chatCard(image: image)
                            case .empty, .failure: chatCard(image: nil)
                            @unknown default: chatCard(image: nil)
                            }
                        }
                    } else {
                        chatCard(image: nil)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                .overlay(
                    Color.white.opacity(0.01)
                        .modifier(RippleModifier(rippleColor: Color.black.opacity(0.35), touchLocation: touchLocation, isPressed: isPressed && frontCardIndex == 2))
                        .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                        .allowsHitTesting(false)
                )
                .background(
                    TouchLocatingView { location in
                        if !isPressed && frontCardIndex == 2 {
                            touchLocation = location
                        }
                    }
                )
                .overlay(RoundedRectangle(cornerRadius: 42, style: .continuous).stroke(Color(red: 223/255, green: 223/255, blue: 223/255), lineWidth: 0.5))
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
                        .modifier(RippleModifier(rippleColor: Color.black.opacity(0.35), touchLocation: touchLocation, isPressed: isPressed && frontCardIndex == 1))
                        .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
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
                        .modifier(RippleModifier(rippleColor: Color.black.opacity(0.35), touchLocation: touchLocation, isPressed: isPressed && frontCardIndex == 0))
                        .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
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
        .onChange(of: isLongPressing) { oldValue, newValue in
            if newValue {
                withAnimation(.easeIn(duration: 0.2)) {
                    showChevrons = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    if isLongPressing {
                        withAnimation(.easeOut(duration: 0.4)) {
                            showChevrons = false
                        }
                    }
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    showChevrons = false
                }
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
                isAnnotationModeActive = false
                if frontCardIndex != 0 {
                    // Delay reset so the card can slide out right during collapse
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        frontCardIndex = 0
                    }
                } else {
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
    private func annotationModeButton() -> some View {
        Button(action: {
            withAnimation(.bouncy(duration: 0.48, extraBounce: 0.18)) {
                if isAnnotationModeActive {
                    isAnnotationModeActive = false
                } else {
                    isAnnotationModeActive = true
                }
            }
        }) {
            HStack(spacing: 12) {
                if isAnnotationModeActive {
                    Text("Annotation Mode")
                        .font(.custom("InclusiveSans-Regular", size: 16))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.leading, 20)
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.trailing, 18)
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                } else {
                    Image("PencilSimpleLine")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.textDark)
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
            }
            .frame(height: 56)
            .frame(minWidth: 56)
            .background(
                ZStack {
                    // Visible base fill ensuring contrast and full alpha for ripple
                    Capsule(style: .continuous)
                        .fill(isAnnotationModeActive ? Color(red: 24/255, green: 24/255, blue: 24/255) : Color.white)
                    
                    // Liquid glass sheen overlay
                    Color.clear
                        .glassEffect(
                            .regular.tint(
                                isAnnotationModeActive
                                    ? Color.black.opacity(0.3)
                                    : Color.white.opacity(0.2)
                            ),
                            in: .capsule
                        )
                    
                    // Subtle perimeter stroke
                    Capsule(style: .continuous)
                        .stroke(
                            isAnnotationModeActive ? Color.white.opacity(0.14) : Color.black.opacity(0.06),
                            lineWidth: 0.5
                        )
                }
            )
            .clipShape(Capsule(style: .continuous))
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(RippleButtonStyle(rippleColor: isAnnotationModeActive ? Color.white.opacity(0.4) : Color.black.opacity(0.3)))
        .shadow(
            color: Color.black.opacity(isAnnotationModeActive ? 0.22 : 0.10),
            radius: isAnnotationModeActive ? 10 : 6,
            x: 0,
            y: isAnnotationModeActive ? 5 : 3
        )
    }
    
    @ViewBuilder
    private func articleDetailCard(image: Image?) -> some View {
        ZStack(alignment: .top) {
            // Main scrollable content
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Spacer to clear the fixed header area
                    Spacer()
                        .frame(height: 190)
                    
                    // Article Content
                    if let parsedStr = try? AttributedString(markdown: article.content) {
                        let attrStr: AttributedString = {
                            var str = parsedStr
                            var breakIndices = [AttributedString.Index]()
                            for (intent, range) in str.runs[\.presentationIntent] {
                                if let intent = intent {
                                    if range.upperBound < str.endIndex {
                                        breakIndices.append(range.upperBound)
                                    }
                                    for component in intent.components {
                                        if case .header(let level) = component.kind {
                                            let size: CGFloat = level == 1 ? 24 : (level == 2 ? 22 : 20)
                                            str[range].font = .system(size: size, weight: .bold)
                                        }
                                    }
                                }
                            }
                            for index in breakIndices.sorted(by: >) {
                                str.insert(AttributedString("\n\n"), at: index)
                            }
                            return str
                        }()
                        Text(attrStr)
                            .foregroundColor(Color(white: 0.35))
                            .lineSpacing(6)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 120) // Space for FAB and dots
                    } else {
                        Text(article.content)
                            .foregroundColor(Color(white: 0.35))
                            .lineSpacing(6)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 120) // Space for FAB and dots
                    }
                }
                .padding(.top, 16)
            }
            
            // Fixed Header overlay (sits above ScrollView)
            articleHeaderView(image: image)
            
            // Bottom Grab Handle for Swiping Cards (only when expanded)
            // Rendered before the FAB so it doesn't blur the button
            if isExpanded && !isAnnotationModeActive {
                grabHandle()
                    .transition(.opacity)
            }
            
            // Floating Action Button (FAB)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    annotationModeButton()
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
        }
        .background {
            // Full card background: #F5F5F5 base + blurred image on top
            ZStack {
                Color.white
                
                if let image = image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .figmaLayerBlur(radius: 19)
                        .opacity(0.16)
                }
            }
        }
    }
    
    @ViewBuilder
    private func articleHeaderView(image: Image?) -> some View {
        ZStack(alignment: .top) {
            // Progressive blur behind the header to fade the scrolling text
            ProgressiveBlurView(height: 210, edge: .top)
                .allowsHitTesting(false)
            
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .top) {
                    // Sharp Thumbnail Image
                    if let image = image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 92)
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
                            Color.clear
                                .glassEffect(.regular.tint(Color.white.opacity(0.4)), in: .circle)
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
                            Color.clear
                                .glassEffect(.regular.tint(Color.white.opacity(0.4)), in: .circle)
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    // Publication & Author
                    HStack(spacing: 12) {
                        Image(article.publication)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 32, height: 32)
                            .background(Color.white)
                            .clipShape(Circle())
                        
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
                    
                    // Title
                    Text(article.title)
                        .font(.custom("InclusiveSans-Regular", size: 18))
                        .foregroundColor(.textDark)
                        .bold()
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
        }
    }
    
    @ViewBuilder
    private func chatCard(image: Image?) -> some View {
        ZStack {
            if isExpanded {
                if !isAnnotationModeActive {
                    // Bottom Grab Handle for Swiping Cards
                    // Rendered before the content so it doesn't blur the chat input
                    grabHandle()
                        .transition(.opacity)
                }
                
                VStack(spacing: 0) {
                    articleHeaderView(image: image)
                    
                    // Middle swipeable area in chat card
                    Color.clear
                        .contentShape(Rectangle())
                        .overlay(carouselGestureLayer())
                    
                    chatInputView()
                        .padding(.bottom, 48) // Snug against the grab handle area
                }
            }
        }
        .background {
            // Full card background: #F5F5F5 base + blurred image on top
            ZStack {
                Color.white
                
                if let image = image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .figmaLayerBlur(radius: 19)
                        .opacity(0.16)
                        .clipped()
                }
            }
            .ignoresSafeArea(.all, edges: [])
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
                            .foregroundColor(Color(white: 0.35))
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
            if isExpanded && !isAnnotationModeActive {
                grabHandle()
                    .transition(.opacity)
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
                            Color.clear
                                .glassEffect(.regular.tint(Color.white.opacity(0.4)), in: .circle)
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
                            Color.clear
                                .glassEffect(.regular.tint(Color.white.opacity(0.4)), in: .circle)
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        annotationModeButton()
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
                    .frame(height: 270)
                    .clipped()
                    .progressiveBleedBlur(radius: 24, offset: 0.75, direction: .bottom, steps: 4)
            } else {
                Color.clear.frame(height: 400)
            }
        }
        .background {
            // Full card background: #F5F5F5 base + blurred image on top
            ZStack {
                Color.white
                
                if let image = image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .figmaLayerBlur(radius: 19)
                        .opacity(0.16)
                }
            }
        }
        .onTapGesture(coordinateSpace: .local) { location in
            if !isExpanded {
                touchLocation = location
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    onToggle()
                }
            }
        }
    }
    
    @ViewBuilder
    private func grabHandle() -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            ZStack(alignment: .bottom) {
                // Progressive blur behind the grabber
                ProgressiveBlurView(height: 52, edge: .bottom)
                    .allowsHitTesting(false)
                
                HStack(spacing: 40) {
                    if showChevrons {
                        ShimmerChevron(isLeft: true, isAnimating: $showChevrons)
                            .transition(.opacity)
                    }
                    
                    VStack(spacing: 8) {
                        VStack(spacing: 3) {
                            HStack(spacing: 3) {
                                Circle().frame(width: 3, height: 3)
                                Circle().frame(width: 3, height: 3)
                                Circle().frame(width: 3, height: 3)
                            }
                            HStack(spacing: 3) {
                                Circle().frame(width: 3, height: 3)
                                Circle().frame(width: 3, height: 3)
                                Circle().frame(width: 3, height: 3)
                            }
                        }
                        .foregroundColor(Color.textSecondary.opacity(0.4))
                    }
                    .frame(height: 24)
                    
                    if showChevrons {
                        ShimmerChevron(isLeft: false, isAnimating: $showChevrons)
                            .transition(.opacity)
                    }
                }
                .frame(height: 24)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity)
                .frame(height: 52, alignment: .bottom)
                .background(Color.white.opacity(0.001))
                .contentShape(Rectangle())
                .overlay(carouselGestureLayer()) // Gesture is now ONLY at the bottom
            }
        }
    }
    
    @ViewBuilder
    private func chatInputView() -> some View {
        HStack(alignment: .bottom, spacing: 12) {
            TextField("Chat with the article...", text: $chatInputText, axis: .vertical)
                .font(.custom("InclusiveSans-Regular", size: 16))
                .foregroundColor(.textDark)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .frame(minHeight: 56)
                .lineLimit(1...5)
            
            Button(action: {
                chatInputText = ""
            }) {
                ZStack {
                    Circle()
                        .fill(chatInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color(red: 40/255, green: 40/255, blue: 40/255) : Color.brandGreen)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "arrow.up")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(.trailing, 6)
            .padding(.bottom, 6)
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white)
        )
        .padding(.horizontal, 12)
    }
    
    @ViewBuilder
    private func carouselGestureLayer() -> some View {
        Color.white.opacity(0.001)
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard !isAnnotationModeActive else { return }
                        
                        if !isLongPressing {
                            let cardX = value.startLocation.x
                            let cardY = expandedCardHeight - 26
                            touchLocation = CGPoint(x: cardX, y: cardY)
                            isPressed = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isPressed = false
                            }
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.65)) {
                                isLongPressing = true
                            }
                        }
                        
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        guard !isAnnotationModeActive else { return }
                        let predicted = value.predictedEndTranslation.width
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                            isLongPressing = false
                            if dragOffset > 40 || predicted > 80 {
                                frontCardIndex = (frontCardIndex - 1 + 3) % 3
                            } else if dragOffset < -40 || predicted < -80 {
                                frontCardIndex = (frontCardIndex + 1) % 3
                            }
                            dragOffset = 0
                        }
                    }
            )
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

struct ShimmerChevron: View {
    var isLeft: Bool
    @Binding var isAnimating: Bool
    
    @State private var shimmerPhase: CGFloat = 0
    
    private var baseChevron: some View {
        HStack(spacing: -5) {
            ForEach(0..<4, id: \.self) { _ in
                Image(systemName: isLeft ? "chevron.compact.left" : "chevron.compact.right")
                    .font(.system(size: 18, weight: .heavy))
            }
        }
    }
    
    var body: some View {
        baseChevron
            .foregroundColor(Color.textSecondary.opacity(0.2))
            .overlay(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: Color.textSecondary, location: 0.4),
                        .init(color: .white, location: 0.5),
                        .init(color: Color.textSecondary, location: 0.6),
                        .init(color: .clear, location: 1.0)
                    ]),
                    startPoint: UnitPoint(x: shimmerPhase, y: 0),
                    endPoint: UnitPoint(x: shimmerPhase + 0.5, y: 0)
                )
                .mask(baseChevron)
            )
            .offset(y: -2)
            .onChange(of: isAnimating) { oldValue, newValue in
                if newValue {
                    runShimmer()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        if isAnimating { runShimmer() }
                    }
                } else {
                    shimmerPhase = isLeft ? 1.5 : -0.5
                }
            }
            .onAppear {
                shimmerPhase = isLeft ? 1.5 : -0.5
            }
    }
    
    private func runShimmer() {
        // Force reset without animation
        withAnimation(.none) {
            shimmerPhase = isLeft ? 1.5 : -0.5
        }
        
        withAnimation(.linear(duration: 1.0)) {
            shimmerPhase = isLeft ? -0.5 : 1.5
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace
    FeedView(appState: .constant(.feed), animationNamespace: namespace)
}
import SwiftUI
