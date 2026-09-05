import SwiftUI

struct SavedArticleRowView: View {
    let article: SavedArticle
    let isAnnotationTab: Bool
    
    @State private var loadedImage: UIImage? = nil
    
    private var halfWidth: CGFloat {
        UIScreen.main.bounds.width / 2
    }
    
    private let cardHeight: CGFloat = 120
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left: Article Thumbnail with Publisher Badge (Half Width)
            ZStack(alignment: .topLeading) {
                // Image
                Group {
                    if let image = loadedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: halfWidth, height: cardHeight)
                            .clipped()
                    } else {
                        Color.secondaryBackground
                            .frame(width: halfWidth, height: cardHeight)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 20))
                                    .foregroundColor(.textSecondary.opacity(0.35))
                            )
                    }
                }
                .frame(width: halfWidth, height: cardHeight)
                .clipShape(Rectangle())
                
                // Publisher Circular Badge
                publisherBadge(name: article.publication)
                    .padding(.leading, 8)
                    .padding(.top, 8)
            }
            .frame(width: halfWidth, height: cardHeight)
            
            // Right: Text Content & Annotation Indicator (Half Width)
            VStack(alignment: .leading, spacing: 6) {
                Text(article.title)
                    .font(.custom("InclusiveSans-Regular", size: 14.5))
                    .foregroundColor(.textDark)
                    .lineLimit(4)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
                
                Spacer(minLength: 0)
                
                if !isAnnotationTab {
                    // Saved Tab: Show Author
                    Text("by \(article.author)")
                        .font(.custom("InclusiveSans-Regular", size: 13))
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                } else {
                    // Annotation Tab: Show Colored Dot or Note Badge
                    annotationIndicator(for: article.annotation)
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, 16)
            .padding(.vertical, 2)
            .frame(width: halfWidth, height: cardHeight, alignment: .leading)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onAppear {
            if let url = article.imageURL, loadedImage == nil {
                if let cached = RemoteImageManager.shared.image(for: url) {
                    loadedImage = cached
                }
            }
        }
        .task(id: article.imageURL) {
            guard let url = article.imageURL else {
                loadedImage = nil
                return
            }
            if let cached = RemoteImageManager.shared.image(for: url) {
                loadedImage = cached
            } else {
                let img = await RemoteImageManager.shared.load(url: url)
                if !Task.isCancelled {
                    withAnimation(.easeIn(duration: 0.15)) {
                        loadedImage = img
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func publisherBadge(name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: 26, height: 26)
            .background(Color.white)
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 1)
    }
    
    @ViewBuilder
    private func annotationIndicator(for item: AnnotationItem?) -> some View {
        switch item {
        case .circle(let color):
            Circle()
                .fill(color)
                .frame(width: 22, height: 22)
                .shadow(color: color.opacity(0.3), radius: 3, x: 0, y: 1)
        case .note:
            HStack(spacing: 5) {
                Text("“")
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundColor(.textSecondary)
                
                Text("Note")
                    .font(.custom("InclusiveSans-Regular", size: 13))
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.secondaryBackground)
            .clipShape(Capsule())
        case .none:
            Circle()
                .fill(Color(red: 0.204, green: 0.780, blue: 0.349)) // Default green
                .frame(width: 22, height: 22)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        SavedArticleRowView(
            article: SavedMockData.savedArticles[0],
            isAnnotationTab: false
        )
        SavedArticleRowView(
            article: SavedMockData.annotatedArticles[0],
            isAnnotationTab: true
        )
        SavedArticleRowView(
            article: SavedMockData.annotatedArticles[3],
            isAnnotationTab: true
        )
    }
}
