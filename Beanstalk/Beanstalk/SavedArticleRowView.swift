import SwiftUI

struct SavedArticleRowView: View {
    let article: SavedArticle
    let isAnnotationTab: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Left: Article Thumbnail with Publisher Badge
            ZStack(alignment: .topLeading) {
                // Image
                Group {
                    if let url = article.imageURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 170, height: 118)
                                    .clipped()
                            case .failure:
                                Color.secondaryBackground
                                    .frame(width: 170, height: 118)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.textSecondary.opacity(0.5))
                                    )
                            case .empty:
                                Color.secondaryBackground
                                    .frame(width: 170, height: 118)
                            @unknown default:
                                Color.secondaryBackground
                                    .frame(width: 170, height: 118)
                            }
                        }
                    } else {
                        Color.secondaryBackground
                            .frame(width: 170, height: 118)
                    }
                }
                .frame(width: 170, height: 118)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                // Publisher Circular Badge
                publisherBadge(name: article.publication)
                    .padding(.leading, 8)
                    .padding(.top, 8)
            }
            .frame(width: 170, height: 118)
            
            // Right: Text Content & Annotation Indicator
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 118)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private func publisherBadge(name: String) -> some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(Color(red: 223/255, green: 223/255, blue: 223/255), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
            
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .clipShape(Circle())
        }
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
