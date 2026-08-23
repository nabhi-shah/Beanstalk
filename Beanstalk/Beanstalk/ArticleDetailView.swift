import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header Image
                if let url = article.thumbnailURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle().fill(Color.secondaryBackground)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Rectangle().fill(Color.secondaryBackground)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 300)
                    .clipped()
                } else {
                    Rectangle()
                        .fill(Color.secondaryBackground)
                        .frame(height: 300)
                        .overlay(
                            Text(article.publication)
                                .font(.custom("InclusiveSans-Regular", size: 32))
                                .foregroundColor(.textSecondary.opacity(0.3))
                        )
                }
                
                VStack(alignment: .leading, spacing: 24) {
                    // Meta Info
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(article.publication)
                                .font(.custom("InclusiveSans-Regular", size: 14))
                                .foregroundColor(.brandGreen)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.brandGreen.opacity(0.1))
                                .clipShape(Capsule())
                            
                            Spacer()
                            
                            Text(article.date)
                                .font(.custom("InclusiveSans-Regular", size: 14))
                                .foregroundColor(.textSecondary)
                        }
                        
                        Text(article.title)
                            .font(.custom("InclusiveSans-Regular", size: 26))
                            .foregroundColor(.textDark)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        if !article.author.isEmpty {
                            Text("By \(article.author)")
                                .font(.custom("InclusiveSans-Regular", size: 16))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    // AI Summary Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.brandGreen)
                            Text("AI Summary")
                                .font(.custom("InclusiveSans-Regular", size: 16))
                                .foregroundColor(.textDark)
                        }
                        
                        Text(article.aiSummary)
                            .font(.custom("InclusiveSans-Regular", size: 16))
                            .foregroundColor(.textDark)
                            .lineSpacing(4)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.5))
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .glassEffect(.regular.tint(Color.brandGreen.opacity(0.1)))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.brandGreen.opacity(0.3), lineWidth: 1)
                    )
                    
                    Divider()
                    
                    // Article Content
                    Text(article.content)
                        .font(.custom("InclusiveSans-Regular", size: 18))
                        .foregroundColor(.textDark)
                        .lineSpacing(8)
                }
                .padding(24)
                .background(Color.appBackground)
                .cornerRadius(32, corners: [.topLeft, .topRight])
                .offset(y: -32) // Pull up over the image
                .padding(.bottom, -32) // Adjust padding so scrollview isn't too long
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textDark)
                        .padding(10)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                }
            }
        }
    }
}

#Preview {
    ArticleDetailView(article: MockData.articles[0])
}
