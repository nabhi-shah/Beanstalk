import SwiftUI

struct FeedView: View {
    @Binding var appState: AppState
    var animationNamespace: Namespace.ID
    
    @State private var selectedTab: MainTab = .home
    
    var body: some View {
        NavigationStack {
            UnionTabView(selection: $selectedTab, tabs: [.home, .search, .saved, .profile]) {
                FeedContentView().unionTab(MainTab.home)
                
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
    var body: some View {
        ZStack(alignment: .top) {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Spacer()
                    Text("Beanstalk.")
                        .font(.custom("InclusiveSans-Regular", size: 28))
                        .foregroundColor(.brandGreen)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    Spacer()
                }
                .background(Color.appBackground)
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(MockData.articles) { article in
                            NavigationLink(destination: ArticleDetailView(article: article)) {
                                ArticleRowView(article: article)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 120) // Space for TabBar
                }
            }
        }
    }
}

struct ArticleRowView: View {
    let article: Article
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            Color.secondaryBackground
            
            // Image with fade mask
            VStack(spacing: 0) {
                if let url = article.thumbnailURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            Rectangle().fill(Color.gray.opacity(0.1))
                        }
                    }
                    .frame(height: 280)
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .white, location: 0.6),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                Spacer()
            }
            
            // Text Content Overlay
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    // Publication Logo
                    ZStack {
                        Circle().fill(Color.white)
                            .frame(width: 32, height: 32)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        
                        Image(article.publication)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .clipShape(Circle())
                    }
                    
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
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 400)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    @Previewable @Namespace var namespace
    FeedView(appState: .constant(.feed), animationNamespace: namespace)
}
