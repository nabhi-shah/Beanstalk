import SwiftUI
import Glur

struct ArticleDetailView: View {
    let article: Article
    var animation: Namespace.ID
    @Binding var selectedArticle: Article?
    
    var body: some View {
        GeometryReader { geo in
            let windowInsets = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.windows.first?.safeAreaInsets
            let safeTop = max(windowInsets?.top ?? geo.safeAreaInsets.top, 20)
            let safeBottom = max(windowInsets?.bottom ?? geo.safeAreaInsets.bottom, 20)
            let cardWidth = geo.size.width - 24 // 12px padding on each side
            let dotsHeight: CGFloat = 20
            let cardGap: CGFloat = 12
            let cardHeight = geo.size.height - safeTop - safeBottom - dotsHeight - cardGap
            
            ZStack {
                // White background behind the modal
                Color.white
                
                VStack(spacing: cardGap) {
                    ZStack(alignment: .top) {
                        // Base background: #F5F5F5 + blurred image at 26% opacity covering entire card
                        ZStack {
                            Color(red: 245/255, green: 245/255, blue: 245/255)
                            
                            if let url = article.thumbnailURL {
                                AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: cardWidth, height: cardHeight)
                                        .clipped()
                                        .figmaLayerBlur(radius: 94)
                                        .opacity(0.26)
                                }
                                }
                            }
                        }
                        .frame(width: cardWidth, height: cardHeight)
                        .clipped()
                        
                        // Sharp image at top, fixed height
                        VStack(spacing: 0) {
                            Color.clear
                                .overlay(
                                    GeometryReader { geo in
                                        if let url = article.thumbnailURL {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: geo.size.width, height: geo.size.height)
                                                       
                                                        .progressiveBleedBlur(radius: 24, offset: 0.75, direction: .bottom, steps: 5)
                                                default:
                                                    Color.clear
                                                }
                                            }
                                        } else {
                                            Color.clear
                                        }
                                    }
                                )
                                .frame(height: 290)
                               
                            
                            Spacer(minLength: 0)
                        }
                        .frame(width: cardWidth, height: cardHeight)
                        .zIndex(0)
                        
                        // Content Section (Bottom) — scrollable if needed
                        VStack(spacing: 0) {
                            Color.clear.frame(height: 290) // Push content strictly below the image area
                            
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
                            .padding(.top, 6)
                            .padding(.bottom, 64)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Spacer(minLength: 0)
                        }
                        .frame(width: cardWidth, height: cardHeight)
                        .zIndex(1)
                        
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
                            
                            // Bottom FAB Area
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
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                        }
                        .frame(width: cardWidth, height: cardHeight)
                    }
                    .frame(width: cardWidth, height: cardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                    .matchedGeometryEffect(id: "card-\(article.id)", in: animation)
                    
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
                    .frame(height: dotsHeight)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, safeTop)
                .padding(.bottom, safeBottom)
            }
        }
        .ignoresSafeArea()
    }
}
