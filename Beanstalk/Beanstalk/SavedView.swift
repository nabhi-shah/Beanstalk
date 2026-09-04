import SwiftUI

struct SavedView: View {
    @State private var selectedTab: SavedTabType = .saved
    @State private var searchText: String = ""
    @State private var isSearchActive: Bool = false
    @State private var isAscendingDate: Bool = false
    @State private var selectedPublisher: String? = nil
    @FocusState private var isSearchFieldFocused: Bool
    @State private var searchTouchLocation: CGPoint? = nil
    @State private var isSearchPressed: Bool = false
    
    // Data sources
    private var baseArticles: [SavedArticle] {
        selectedTab == .saved ? SavedMockData.savedArticles : SavedMockData.annotatedArticles
    }
    
    // Filtered and sorted articles
    private var displayedArticles: [SavedArticle] {
        var articles = baseArticles
        
        // Filter by search query
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            articles = articles.filter {
                $0.title.localizedCaseInsensitiveContains(query) ||
                $0.author.localizedCaseInsensitiveContains(query) ||
                $0.publication.localizedCaseInsensitiveContains(query)
            }
        }
        
        // Filter by publisher if active
        if let publisher = selectedPublisher {
            articles = articles.filter { $0.publication == publisher }
        }
        
        // Sort by date
        articles.sort {
            isAscendingDate ? $0.date < $1.date : $0.date > $1.date
        }
        
        return articles
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.appBackground
                .ignoresSafeArea()
            
            // Scrollable Article Feed
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Space for the sticky top section (Tabs + Controls + Progressive Blur)
                    Color.clear
                        .frame(height: 195)
                    
                    if displayedArticles.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(displayedArticles) { article in
                            SavedArticleRowView(
                                article: article,
                                isAnnotationTab: selectedTab == .annotations
                            )
                        }
                    }
                }
                .padding(.bottom, 120) // Clearance for floating UnionTabView
            }
            .scrollDismissesKeyboard(.immediately)
            
            // Bottom Progressive Blur (matching home feed)
            VStack {
                Spacer()
                ProgressiveBlurView(height: 140, edge: .bottom)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            
            // Sticky Top Header with Progressive Blur
            stickyHeader
        }
    }
    
    // MARK: - Sticky Top Section
    private var stickyHeader: some View {
        ZStack(alignment: .top) {
            // Progressive blur & gradient backdrop
            ZStack(alignment: .top) {
                ProgressiveBlurView(height: 200, edge: .top)
                
                LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(0.96), location: 0.0),
                        .init(color: Color.white.opacity(0.85), location: 0.65),
                        .init(color: Color.white.opacity(0.0), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
                .ignoresSafeArea()
            }
            
            VStack(spacing: 12) {
                // Top Tabs: Saved & Annotations
                SavedGooeyTabView(selectedTab: $selectedTab)
                    .padding(.top, 8)
                
                // Controls Row: Search, Date Sort, Filter
                controlsRow
            }
            .padding(.top, 4)
        }
        .frame(height: 185, alignment: .top)
    }
    
    // MARK: - Controls Row (Search, Date Sort, Filter)
    private var controlsRow: some View {
        HStack(spacing: 8) {
            // Search Bar
            HStack(spacing: 10) {
                Image("magnifying-glass")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.textSecondary)
                
                TextField(
                    "",
                    text: $searchText,
                    prompt: Text("Search")
                        .foregroundColor(.textSecondary)
                        .font(.custom("InclusiveSans-Regular", size: 16))
                )
                .font(.custom("InclusiveSans-Regular", size: 16))
                .foregroundColor(.textDark)
                .focused($isSearchFieldFocused)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image("x-circle-fill")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundColor(.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .overlay(
                Capsule()
                    .fill(Color.white.opacity(0.01))
                    .modifier(RippleModifier(rippleColor: Color.black.opacity(0.2), touchLocation: searchTouchLocation, isPressed: isSearchPressed))
                    .clipShape(Capsule())
                    .allowsHitTesting(false)
            )
            .background(
                Color.clear
                    .glassEffect(.regular, in: .capsule)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            .contentShape(Capsule())
            .frame(maxWidth: .infinity)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isSearchPressed {
                            searchTouchLocation = value.location
                            isSearchPressed = true
                        }
                    }
                    .onEnded { _ in
                        isSearchPressed = false
                        if !isSearchActive {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isSearchActive = true
                                isSearchFieldFocused = true
                            }
                        }
                    }
            )
            
            // Sort Button (Date)
            if !isSearchActive {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        isAscendingDate.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Date")
                            .font(.custom("InclusiveSans-Regular", size: 16))
                            .foregroundColor(.textDark)
                        
                        Image(isAscendingDate ? "sort-ascending" : "sort-descending")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.textDark)
                    }
                    .padding(.horizontal, 15)
                    .frame(height: 48)
                    .background(Capsule().fill(Color.white.opacity(0.01)))
                    .contentShape(Capsule())
                }
                .buttonStyle(RippleButtonStyle(rippleColor: Color.black.opacity(0.2)))
                .background(
                    Color.clear
                        .glassEffect(.regular, in: .capsule)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.85)),
                    removal: .opacity.combined(with: .scale(scale: 0.85))
                ))
            }
            
            // Filter Button
            if !isSearchActive {
                Menu {
                    Button("All Publications") {
                        selectedPublisher = nil
                    }
                    Divider()
                    Button("NY Times") { selectedPublisher = "NY Times" }
                    Button("Wall Street Journal") { selectedPublisher = "Wall Street Journal" }
                    Button("Financial Times") { selectedPublisher = "Financial Times" }
                    Button("The Economist") { selectedPublisher = "The Economist" }
                    Button("The Washington Post") { selectedPublisher = "The Washington Post" }
                    Button("Barron’s") { selectedPublisher = "Barron’s" }
                    Button("CNBC") { selectedPublisher = "CNBC" }
                } label: {
                    ZStack {
                        Image(selectedPublisher != nil ? "funnel-fill" : "funnel")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(selectedPublisher != nil ? .brandGreen : Color.textDark)
                    }
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Color.white.opacity(0.01)))
                    .contentShape(Circle())
                }
                .buttonStyle(RippleButtonStyle(rippleColor: Color.black.opacity(0.2)))
                .background(
                    Color.clear
                        .glassEffect(.regular, in: .circle)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.85)),
                    removal: .opacity.combined(with: .scale(scale: 0.85))
                ))
            }
            
            // X Button when Search is Active
            if isSearchActive {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        searchText = ""
                        isSearchActive = false
                        isSearchFieldFocused = false
                    }
                } label: {
                    ZStack {
                        Image("x")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.textDark)
                    }
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Color.white.opacity(0.01)))
                    .contentShape(Circle())
                }
                .buttonStyle(RippleButtonStyle(rippleColor: Color.black.opacity(0.2)))
                .background(
                    Color.clear
                        .glassEffect(.regular, in: .circle)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.85)),
                    removal: .opacity.combined(with: .scale(scale: 0.85))
                ))
            }
        }
        .padding(.horizontal, 24)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSearchActive)
        .onChange(of: isSearchFieldFocused) { _, focused in
            if focused && !isSearchActive {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isSearchActive = true
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 60)
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 44))
                .foregroundColor(.textSecondary.opacity(0.6))
            
            Text("No articles found")
                .font(.custom("InclusiveSans-Regular", size: 17))
                .foregroundColor(.textDark)
            
            Text("Try searching with different keywords or resetting filters.")
                .font(.custom("InclusiveSans-Regular", size: 14))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

#Preview {
    SavedView()
}
