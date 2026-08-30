import SwiftUI
import Glur

struct ArticleDetailView: View {
    let article: Article
    var animation: Namespace.ID
    @Binding var selectedArticle: Article?
    
    var body: some View {
        ZStack {
            // White background behind the modal
            Color.white.ignoresSafeArea()
            
            ZStack(alignment: .top) { // Align to top so image anchors to top
                // Base background for the expanded card (covers the bottom text area)
                ZStack {
                    Color(red: 245/255, green: 245/255, blue: 245/255)
                    
                    if let url = article.thumbnailURL {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .blur(radius: 94)
                                    .opacity(0.26)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .clipped()
                            }
                        }
                    }
                }
                
                // Background Image
                Color.clear
                    .overlay(
                        GeometryReader { proxy in
                            if let url = article.thumbnailURL {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: proxy.size.width, height: proxy.size.height)
                                            .clipped()
                                            .glur(radius: 24.0, offset: 0.72, interpolation: 0.28, direction: .down)
                                    default:
                                        Color.clear
                                    }
                                }
                            } else {
                                Color.clear
                            }
                        }
                    )
                    .frame(height: 420) // Match ArticleRowView minHeight to prevent zoom
                    .matchedGeometryEffect(id: "background-\(article.id)", in: animation)
                
                // Content Section (Bottom)
                VStack {
                    Spacer()
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
                            .multilineTextAlignment(.leading)
                            
                        Text(article.aiSummary)
                            .font(.custom("InclusiveSans-Regular", size: 16))
                            .foregroundColor(.textSecondary)
                            .lineSpacing(4)
                            .padding(.top, 8)
                    }
                    .padding(24)
                    .padding(.top, 48)
                    .padding(.bottom, 64)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: Color(red: 245/255, green: 245/255, blue: 245/255).opacity(0.85), location: 0.2),
                                .init(color: Color(red: 245/255, green: 245/255, blue: 245/255).opacity(1.0), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                
                // Top Buttons
                VStack {
                    HStack {
                        Button(action: { 
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                selectedArticle = nil
                            }
                        }) {
                            Image("CaretLeft")
                                .renderingMode(.template)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.textDark)
                                .frame(width: 44, height: 44)
                                .background(Color(red: 245/255, green: 245/255, blue: 245/255).opacity(0.7))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Button(action: { }) {
                            Image("bookmark")
                                .renderingMode(.template)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.textDark)
                                .frame(width: 44, height: 44)
                                .background(Color(red: 245/255, green: 245/255, blue: 245/255).opacity(0.7))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 64)
                    
                    Spacer()
                    
                    // Bottom FAB
                    HStack {
                        Spacer()
                        Button(action: {}) {
                            Image("PencilSimpleLine")
                                .renderingMode(.template)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.textSecondary)
                                .frame(width: 56, height: 56)
                                .background(Color(red: 245/255, green: 245/255, blue: 245/255))
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
            .matchedGeometryEffect(id: "card-\(article.id)", in: animation)
            .padding(.top, 44) // Status bar
            .padding(.bottom, 34) // Home indicator
            .padding(.horizontal, 12)
            .ignoresSafeArea()
        }
    }
}
