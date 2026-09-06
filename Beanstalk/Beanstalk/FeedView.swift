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
    @State private var isScrollLocked: Bool = false

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
                                    if selectedArticle?.id == article.id {
                                        isScrollLocked = false
                                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                            selectedArticle = nil
                                        }
                                    } else {
                                        isScrollLocked = false
                                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                            selectedArticle = article
                                            scrollProxy.scrollTo(article.id, anchor: .top)
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            if selectedArticle != nil {
                                                isScrollLocked = true
                                            }
                                        }
                                    }
                                }
                            )
                            .id(article.id)
                            .opacity(selectedArticle != nil && selectedArticle?.id != article.id ? 0 : 1)
                            .animation(.easeInOut(duration: 0.3), value: selectedArticle?.id)
                        }
                        
                        // Bottom spacer inside LazyVStack guaranteeing scroll travel to anchor: .top for last card
                        Color.clear
                            .frame(height: selectedArticle != nil ? UIScreen.main.bounds.height : max(UIScreen.main.bounds.height * 0.55, 450))
                            .id("bottomFeedSpacer")
                    }
                    .padding(.horizontal, selectedArticle != nil ? 20 : 12)
                    .padding(.top, 48)
                }
                .scrollDisabled(isScrollLocked)
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
    @State private var chatInputText: String = ""
    @State private var isAnnotationModeActive: Bool = false
    @State private var highlightSweepProgress: Double = 0.0
    @State private var highlightFadeOpacity: Double = 1.0
    @State private var highlightSpans: [HighlightSpan] = []
    @State private var highlightAnimationTask: Task<Void, Never>? = nil
    @State private var isTextSelectable: Bool = false
        @State private var isHighlightAnimating: Bool = false
    @State private var contentHighlights: [HighlightRange] = []
    @State private var summaryHighlights: [HighlightRange] = []
    @State private var isCard1Loaded: Bool = false
    @State private var isCard2Loaded: Bool = false
    @State private var saveButtonState: SaveButtonState = .unsaved
    @State private var loadedImage: UIImage? = nil
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isChatFocused: Bool
    @State private var focusedTextInputMaxY: CGFloat? = nil
    
    private var currentImage: Image? {
        if let loadedImage = loadedImage {
            return Image(uiImage: loadedImage)
        }
        return nil
    }
    
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
                    if isCard2Loaded || frontCardIndex == 2 {
                        chatCard(image: currentImage)
                    } else {
                        cardPlaceholder(color: Color(red: 236/255, green: 236/255, blue: 236/255))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                .overlay(
                    Color.white.opacity(0.01)
                        .modifier(RippleModifier(rippleColor: Color.black.opacity(0.35), touchLocation: touchLocation, isPressed: isLongPressing && frontCardIndex == 2))
                        .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                        .allowsHitTesting(false)
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
                    if isCard1Loaded || frontCardIndex == 1 {
                        articleDetailCard(image: currentImage)
                    } else {
                        cardPlaceholder(color: Color(red: 242/255, green: 242/255, blue: 242/255))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                .overlay(
                    Color.white.opacity(0.01)
                        .modifier(RippleModifier(rippleColor: Color.black.opacity(0.35), touchLocation: touchLocation, isPressed: isLongPressing && frontCardIndex == 1))
                        .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                        .allowsHitTesting(false)
                )
                .overlay(RoundedRectangle(cornerRadius: 42, style: .continuous).stroke(Color(red: 223/255, green: 223/255, blue: 223/255), lineWidth: 0.5))
                .scaleEffect(x: c1.scaleX, y: c1.scaleY)
                .offset(x: c1.xOffset)
                .opacity(c1.opacity)
                .zIndex(c1.zIndex)
                .layoutPriority(-1)
                
                // Card 0 (Main Card)
                let c0 = cardMetrics(for: 0)
                cardContent(image: currentImage)
                .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                .overlay(
                    Color.white.opacity(0.01)
                        .modifier(RippleModifier(rippleColor: Color.black.opacity(0.35), touchLocation: touchLocation, isPressed: isLongPressing && frontCardIndex == 0))
                        .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                        .allowsHitTesting(false)
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
        .offset(y: dynamicKeyboardOffset)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FocusedTextInputMaxY"))) { notification in
            if let maxY = notification.userInfo?["maxY"] as? CGFloat {
                self.focusedTextInputMaxY = maxY
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if isExpanded, let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) {
                    self.keyboardHeight = frame.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                self.keyboardHeight = 0
                self.focusedTextInputMaxY = nil
            }
        }
        .onChange(of: isExpanded) { oldValue, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeIn(duration: 0.2)) {
                        showActions = true
                    }
                }
                // Lazy load Card 1 shortly after the opening transition has completed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isCard1Loaded = true
                    }
                }
                // Lazy load Card 2 progressively after Card 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isCard2Loaded = true
                    }
                }
            } else {
                showActions = false
                isAnnotationModeActive = false
                if frontCardIndex != 0 {
                    // Delay reset so the card can slide out right during collapse
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        frontCardIndex = 0
                        isCard1Loaded = false
                        isCard2Loaded = false
                    }
                } else {
                    frontCardIndex = 0
                    isCard1Loaded = false
                    isCard2Loaded = false
                }
            }
        }
        .onAppear {
            if loadedImage == nil, let url = article.thumbnailURL {
                if let cached = RemoteImageManager.shared.image(for: url) {
                    loadedImage = cached
                }
            }
        }
        .task(id: article.thumbnailURL) {
            guard let url = article.thumbnailURL else { return }
            if let cached = RemoteImageManager.shared.image(for: url) {
                loadedImage = cached
            } else {
                let img = await RemoteImageManager.shared.load(url: url)
                if !Task.isCancelled {
                    withAnimation(.easeIn(duration: 0.2)) {
                        loadedImage = img
                    }
                }
            }
        }
        .onChange(of: isAnnotationModeActive) { oldValue, newValue in
            if newValue {
                triggerHighlightAnimation()
            } else {
                cancelHighlightAnimation()
            }
        }
        .onDisappear {
            cancelHighlightAnimation()
        }
    }
    
    private func triggerHighlightAnimation() {
        isTextSelectable = true
    }
    
    private func cancelHighlightAnimation() {
        isTextSelectable = false
    }
    
    private func generateHighlightSpans() -> [HighlightSpan] {
        let yellowColor = Color(red: 1.0, green: 0.84, blue: 0.20)
        
        return [
            HighlightSpan(
                startFraction: CGFloat.random(in: 0.05...0.25),
                endFraction: CGFloat.random(in: 0.75...0.95),
                color: yellowColor
            ),
            HighlightSpan(
                startFraction: CGFloat.random(in: 0.0...0.2),
                endFraction: CGFloat.random(in: 0.7...0.9),
                color: yellowColor
            ),
            HighlightSpan(
                startFraction: CGFloat.random(in: 0.15...0.35),
                endFraction: CGFloat.random(in: 0.8...1.0),
                color: yellowColor
            )
        ]
    }
    
    // Placeholder view for lazy loading cards in stack
    @ViewBuilder
    private func cardPlaceholder(color: Color) -> some View {
        color
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Computed height for expanded state to fill the screen minus safe areas, dots, and padding
    private var expandedCardHeight: CGFloat {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.windows.first
        let safeTop = max(window?.safeAreaInsets.top ?? 59, 47)
        let safeBottom = max(window?.safeAreaInsets.bottom ?? 34, 34)
        // Screen height - safeTop - safeBottom - 20 (dots) - 12 (spacing)
        let calculated = UIScreen.main.bounds.height - safeTop - safeBottom - 32
        return max(calculated, 600) // Ensure it doesn't get ridiculously small on tiny screens
    }
    
    private var dynamicKeyboardOffset: CGFloat {
        guard keyboardHeight > 0 else { return 0 }
        guard let maxY = focusedTextInputMaxY else {
            return -keyboardHeight * 0.85 // fallback
        }
        
        let screenHeight = UIScreen.main.bounds.height
        let keyboardTop = screenHeight - keyboardHeight
        
        // Ensure the input field's bottom (maxY) is above the keyboard top by at least 14 points padding
        let neededShift = maxY - keyboardTop + 14
        
        if neededShift > 0 {
            // Shift up just enough so the menu is visible, capped at full keyboard height to avoid clipping top UI
            return -min(neededShift, keyboardHeight)
        } else {
            // The input is naturally above the keyboard, no shift needed
            return 0
        }
    }
    
    @ViewBuilder
    private func annotationModeButton() -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                isAnnotationModeActive.toggle()
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
                Capsule(style: .continuous)
                    .fill(isAnnotationModeActive ? Color.black.opacity(0.18) : Color.white.opacity(0.001))
            )
            .clipShape(Capsule(style: .continuous))
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(RippleButtonStyle(rippleColor: isAnnotationModeActive ? Color.white.opacity(0.3) : Color.black.opacity(0.2)))
        .glassEffect(
            isAnnotationModeActive
                ? .regular.tint(Color.gray.opacity(0.55))
                : .regular,
            in: .capsule
        )
        .shadow(
            color: Color.black.opacity(isAnnotationModeActive ? 0.16 : 0.08),
            radius: isAnnotationModeActive ? 8 : 6,
            x: 0,
            y: isAnnotationModeActive ? 4 : 2
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
                    SelectableTextView(
                        attributedText: article.attributedContent,
                        font: .preferredFont(forTextStyle: .body),
                        textColor: UIColor(white: 0.35, alpha: 1.0),
                        lineSpacing: 6,
                        tintColor: UIColor(Color.brandGreen),
                        highlightedRanges: $contentHighlights
                    )
                    .allowsHitTesting(isTextSelectable)
                    .tint(.brandGreen)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120) // Space for FAB and dots
                }
                .padding(.top, 16)
            }
            
            // Fixed Header overlay (sits above ScrollView)
            articleHeaderView(image: image)
            
            // Bottom Grab Handle for Swiping Cards (only when expanded)
            // Rendered before the FAB so it doesn't blur the button
            if isExpanded && !isAnnotationModeActive {
                grabHandle(isFront: frontCardIndex == 1)
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
    private func glassOverlayButtons() -> some View {
        HStack {
            AdaptiveGlassIconButton(
                iconName: "CaretLeft",
                overrideIsDark: article.isLeadingDark,
                action: onToggle
            )
            
            Spacer()
            
            AdaptiveGlassSaveButton(
                state: $saveButtonState,
                overrideIsDark: article.isTrailingDark
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
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
                    glassOverlayButtons()
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
                VStack(spacing: 0) {
                    articleHeaderView(image: image)
                    
                    Spacer()
                    
                    chatInputView()
                        .padding(.bottom, 52) // Snug against the grab handle area
                }
                
                if !isAnnotationModeActive {
                    // Bottom Grab Handle for Swiping Cards
                    grabHandle(isFront: frontCardIndex == 2)
                        .transition(.opacity)
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
                        SelectableTextView(
                            attributedText: AttributedString(article.aiSummary),
                            font: .preferredFont(forTextStyle: .body),
                            textColor: UIColor(white: 0.35, alpha: 1.0),
                            lineSpacing: 4,
                            tintColor: UIColor(Color.brandGreen),
                            highlightedRanges: $summaryHighlights
                        )
                        .allowsHitTesting(isTextSelectable)
                        .tint(.brandGreen)
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
                grabHandle(isFront: frontCardIndex == 0)
                    .transition(.opacity)
            }
            
            // 3. Action Buttons Overlay
            if isExpanded {
                VStack {
                    glassOverlayButtons()
                    
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

        .conditionalGesture(!isExpanded, TapGesture().onEnded {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
            onToggle()
        })
    }
    
    @ViewBuilder
    private func grabHandle(isFront: Bool = true) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            ZStack(alignment: .bottom) {
                // Progressive blur behind the grabber
                ProgressiveBlurView(height: 52, edge: .bottom)
                    .allowsHitTesting(false)
                
                GrabChevronIndicator(isGrabbed: isLongPressing && isFront)
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
                .focused($isChatFocused)
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
                .background(
                    GeometryReader { geo in
                        Color.clear.onChange(of: isChatFocused) { _, isFocused in
                            if isFocused {
                                NotificationCenter.default.post(name: NSNotification.Name("FocusedTextInputMaxY"), object: nil, userInfo: ["maxY": geo.frame(in: .global).maxY])
                            }
                        }
                    }
                )
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

// MARK: - Annotation Highlight Animation Models & Renderer

struct HighlightSpan: Sendable {
    var startFraction: CGFloat
    var endFraction: CGFloat
    var color: Color
}

struct HighlightRenderer: TextRenderer, Animatable {
    var sweepProgress: Double
    var fadeOpacity: Double
    var spans: [HighlightSpan]
    
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(sweepProgress, fadeOpacity) }
        set {
            sweepProgress = newValue.first
            fadeOpacity = newValue.second
        }
    }
    
    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let lineArray = Array(layout)
        
        // Draw highlight ink backgrounds behind the text
        if sweepProgress > 0 && fadeOpacity > 0 && !spans.isEmpty {
            let validLineIndices = (0..<lineArray.count).filter { lineArray[$0].typographicBounds.rect.width > 20 }
            
            for (index, span) in spans.enumerated() {
                guard index < validLineIndices.count else { continue }
                
                let targetIdx: Int
                if spans.count <= validLineIndices.count {
                    let chunkStart = (validLineIndices.count * index) / spans.count
                    let chunkSize = validLineIndices.count / spans.count
                    targetIdx = chunkStart + (chunkSize / 2)
                } else {
                    targetIdx = index
                }
                
                let targetLine = lineArray[validLineIndices[targetIdx]]
                let lineRect = targetLine.typographicBounds.rect
                
                let fullStartX = lineRect.minX + lineRect.width * span.startFraction
                let fullEndX = lineRect.minX + lineRect.width * span.endFraction
                let fullSpanWidth = max(fullEndX - fullStartX, 10)
                
                let currentWidth = fullSpanWidth * sweepProgress
                guard currentWidth > 0 else { continue }
                
                let highlightRect = CGRect(
                    x: fullStartX - 3,
                    y: lineRect.minY - 1,
                    width: currentWidth + 6,
                    height: lineRect.height + 2
                )
                let path = Path(roundedRect: highlightRect, cornerRadius: 4)
                context.fill(path, with: .color(span.color.opacity(0.38 * fadeOpacity)))
            }
        }
        
        // Draw the text lines on top
        for line in layout {
            context.draw(line)
        }
    }
}

extension View {
    @ViewBuilder
    func textSelectable(_ isSelectable: Bool) -> some View {
        if isSelectable {
            self.textSelection(.enabled)
        } else {
            self.textSelection(.disabled)
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
    
    @ViewBuilder
    func conditionalGesture<G: Gesture>(_ condition: Bool, _ gesture: G) -> some View {
        if condition {
            self.gesture(gesture)
        } else {
            self
        }
    }
}

// MARK: - Isolated High-Performance Grab Chevron Indicator
struct GrabChevronIndicator: View {
    let isGrabbed: Bool
    
    @State private var visibleCount: Int = 0
    @State private var animationTask: Task<Void, Never>? = nil
    
    var body: some View {
        HStack(spacing: 20) {
            chevronGroup(isLeft: true)
            grabDots
            chevronGroup(isLeft: false)
        }
        .frame(height: 24)
        .onChange(of: isGrabbed) { _, grabbed in
            animationTask?.cancel()
            if grabbed {
                animationTask = Task { @MainActor in
                    await runSequence()
                }
            } else {
                withAnimation(.easeOut(duration: 0.12)) {
                    visibleCount = 0
                }
            }
        }
        .onDisappear {
            animationTask?.cancel()
            visibleCount = 0
        }
    }
    
    @ViewBuilder
    private func chevronGroup(isLeft: Bool) -> some View {
        HStack(spacing: -5) {
            if isLeft {
                chevronIcon(isLeft: true, index: 4)
                chevronIcon(isLeft: true, index: 3)
                chevronIcon(isLeft: true, index: 2)
                chevronIcon(isLeft: true, index: 1)
            } else {
                chevronIcon(isLeft: false, index: 1)
                chevronIcon(isLeft: false, index: 2)
                chevronIcon(isLeft: false, index: 3)
                chevronIcon(isLeft: false, index: 4)
            }
        }
        .offset(y: -2)
    }
    
    @ViewBuilder
    private func chevronIcon(isLeft: Bool, index: Int) -> some View {
        Image(systemName: isLeft ? "chevron.compact.left" : "chevron.compact.right")
            .font(.system(size: 18, weight: .heavy))
            .foregroundColor(Color.textSecondary.opacity(0.55))
            .opacity(visibleCount >= index ? 1 : 0)
    }
    
    private var grabDots: some View {
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
        .frame(height: 24)
    }
    
    @MainActor
    private func runSequence() async {
        let stepDuration: UInt64 = 85_000_000 // 85ms
        let holdDuration: UInt64 = 180_000_000 // 180ms
        let pauseDuration: UInt64 = 120_000_000 // 120ms
        
        for _ in 0..<2 {
            for count in 1...4 {
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.08)) {
                    visibleCount = count
                }
                try? await Task.sleep(nanoseconds: stepDuration)
            }
            
            guard !Task.isCancelled else { return }
            try? await Task.sleep(nanoseconds: holdDuration)
            
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.12)) {
                visibleCount = 0
            }
            try? await Task.sleep(nanoseconds: pauseDuration)
        }
    }
}

// MARK: - Dynamic Adaptive Glass Save Button with Blur-Based Morphing
enum SaveButtonState: Equatable {
    case unsaved
    case saved
}

struct BlurMorphModifier: ViewModifier {
    let isActive: Bool
    var blurRadius: CGFloat = 10
    var scale: CGFloat = 0.72
    
    func body(content: Content) -> some View {
        content
            .compositingGroup()
            .blur(radius: isActive ? 0 : blurRadius)
            .scaleEffect(isActive ? 1.0 : scale)
            .opacity(isActive ? 1.0 : 0.0)
    }
}

extension View {
    func blurMorph(active: Bool, blurRadius: CGFloat = 10, scale: CGFloat = 0.72) -> some View {
        self.modifier(BlurMorphModifier(isActive: active, blurRadius: blurRadius, scale: scale))
    }
}

struct AdaptiveGlassSaveButton: View {
    @Binding var state: SaveButtonState
    var overrideIsDark: Bool? = nil
    
    @Environment(\.colorScheme) private var resolvedGlassState
    @Environment(\.articleDidSave) private var articleDidSave
    
    private func handleTap() {
        if state == .saved {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.42, dampingFraction: 0.76)) {
                state = .unsaved
            }
            return
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.46, dampingFraction: 0.70)) {
            state = .saved
        }
        articleDidSave()
    }
    
    var body: some View {
        Button(action: handleTap) {
            AdaptiveGlassSaveButtonContent(state: state, overrideIsDark: overrideIsDark)
        }
        .accessibilityLabel(state == .saved ? "Unsave article" : "Save article")
        .buttonStyle(AdaptiveGlassRippleButtonStyle(overrideIsDark: state == .saved ? true : overrideIsDark))
        .glassEffect(
            state == .saved
                ? .regular.tint(Color.brandGreen.opacity(0.85))
                : .regular,
            in: .circle
        )
        .shadow(
            color: state == .saved ? Color.brandGreen.opacity(0.4) : Color.black.opacity(0.06),
            radius: state == .saved ? 8 : 6,
            x: 0,
            y: state == .saved ? 3 : 2
        )
        .animation(.spring(response: 0.44, dampingFraction: 0.74), value: state)
    }
}

// 💡 Isolated subview to extract the adapted @Environment(\.colorScheme) resolved by .glassEffect()
struct AdaptiveGlassSaveButtonContent: View {
    let state: SaveButtonState
    var overrideIsDark: Bool? = nil
    
    @Environment(\.colorScheme) private var resolvedGlassState
    
    private var isDark: Bool {
        if let override = overrideIsDark {
            return override
        }
        return resolvedGlassState == .dark
    }
    
    var body: some View {
        ZStack {
            // 1. Unsaved State (Outline Bookmark)
            Image("bookmark-simple")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(isDark ? Color(white: 0.88) : .textDark)
                .blurMorph(active: state == .unsaved)
            
            // 2. Saved State (White Fill Save Button)
            Group {
                if UIImage(named: "bookmark-simple-fill") != nil {
                    Image("bookmark-simple-fill")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "bookmark.fill")
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(width: 20, height: 20)
            .foregroundColor(.white)
            .blurMorph(active: state == .saved)
        }
        .frame(width: 44, height: 44)
        .background(
            Circle()
                .fill(Color.brandGreen)
                .opacity(state == .saved ? 0.95 : 0.0)
                .blur(radius: state == .saved ? 0 : 8)
                .scaleEffect(state == .saved ? 1.0 : 0.72)
        )
        .contentShape(Circle())
    }
}

// MARK: - Dynamic Adaptive Glass Button
struct AdaptiveGlassIconButton: View {
    let iconName: String
    var overrideIsDark: Bool? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            AdaptiveGlassIconContent(iconName: iconName, overrideIsDark: overrideIsDark)
        }
        .buttonStyle(AdaptiveGlassRippleButtonStyle(overrideIsDark: overrideIsDark))
        .glassEffect(.regular, in: .circle)
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

// 💡 Isolated subview to extract the adapted @Environment(\.colorScheme) resolved by .glassEffect()
struct AdaptiveGlassIconContent: View {
    let iconName: String
    var overrideIsDark: Bool? = nil
    
    // Automatically receives the glass's resolved state (.light or .dark)
    @Environment(\.colorScheme) private var resolvedGlassState
    
    private var isDark: Bool {
        if let override = overrideIsDark {
            return override
        }
        return resolvedGlassState == .dark
    }
    
    var body: some View {
        Image(iconName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .foregroundColor(isDark ? Color(white: 0.88) : .textDark)
            .frame(width: 44, height: 44)
            .background(Circle().fill(Color.white.opacity(0.01)))
            .contentShape(Circle())
    }
}

struct AdaptiveGlassRippleButtonStyle: ButtonStyle {
    var overrideIsDark: Bool? = nil
    @Environment(\.colorScheme) private var resolvedGlassState
    @State private var touchLocation: CGPoint?
    
    private var isDark: Bool {
        if let override = overrideIsDark {
            return override
        }
        return resolvedGlassState == .dark
    }
    
    func makeBody(configuration: Configuration) -> some View {
        let rippleColor = isDark ? Color.white.opacity(0.35) : Color.black.opacity(0.3)
        configuration.label
            .modifier(RippleModifier(rippleColor: rippleColor, touchLocation: touchLocation, isPressed: configuration.isPressed))
            .background(
                TouchLocatingView { location in
                    if !configuration.isPressed {
                        touchLocation = location
                    }
                }
            )
    }
}

#Preview {
    @Previewable @Namespace var namespace
    FeedView(appState: .constant(.feed), animationNamespace: namespace)
}
