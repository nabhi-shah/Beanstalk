import re

with open("/Users/nabhi/Desktop/Projects/Beanstalk/Beanstalk/Beanstalk/FeedView.swift", "r") as f:
    content = f.read()

# 1. Remove overlay from FeedView
content = re.sub(
    r'\.overlay\(\s*Group\s*\{\s*if let selectedArticle = selectedArticle\s*\{\s*ArticleDetailView[^\}]+\}\s*\}\s*\)',
    '',
    content,
    flags=re.MULTILINE
)

# 2. Update LazyVStack in FeedContentView
new_vstack = """                LazyVStack(spacing: 16) {
                    ForEach(MockData.articles) { article in
                        ArticleRowView(
                            article: article,
                            isExpanded: selectedArticle?.id == article.id,
                            onToggle: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    if selectedArticle?.id == article.id {
                                        selectedArticle = nil
                                    } else {
                                        selectedArticle = article
                                    }
                                }
                            }
                        )
                        .opacity(selectedArticle != nil && selectedArticle?.id != article.id ? 0 : 1)
                        .animation(.easeInOut(duration: 0.3), value: selectedArticle)
                    }
                }"""
content = re.sub(r'LazyVStack\(spacing: 16\)\s*\{.*?\.padding\(\.horizontal, 12\)', new_vstack + '\n                .padding(.horizontal, 12)', content, flags=re.DOTALL)

# 3. Disable scrolling
content = content.replace('.coordinateSpace(name: "scroll")', '.scrollDisabled(selectedArticle != nil)\n            .coordinateSpace(name: "scroll")')

# 4. Replace ArticleRowView
new_row = """struct ArticleRowView: View {
    let article: Article
    var isExpanded: Bool = false
    var onToggle: () -> Void
    
    @State private var showActions: Bool = false
    
    var body: some View {
        Group {
            if let url = article.thumbnailURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        cardContent(image: image)
                    case .empty, .failure:
                        cardContent(image: nil)
                    @unknown default:
                        cardContent(image: nil)
                    }
                }
            } else {
                cardContent(image: nil)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .stroke(Color(red: 223/255, green: 223/255, blue: 223/255), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .onChange(of: isExpanded) { oldValue, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeIn(duration: 0.2)) {
                        showActions = true
                    }
                }
            } else {
                showActions = false
            }
        }
    }
    
    @ViewBuilder
    private func cardContent(image: Image?) -> some View {
        ZStack(alignment: .top) {
            // 2. Content
            ZStack(alignment: .top) {
                // Blurred Image Layer as a separate element, NOT clipped!
                GeometryReader { proxy in
                    if let image = image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()
                            .figmaLayerBlur(radius: 94)
                            .opacity(0.40)
                    }
                }
                .allowsHitTesting(false)
                
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
                    .progressiveBleedBlur(radius: 24, offset: 0.75, direction: .bottom, steps: 5)
            } else {
                Color.clear.frame(height: 400)
            }
        }
        .background {
            // Full card background: #F5F5F5 base + blurred image on top
            ZStack {
                Color(red: 245/255, green: 245/255, blue: 245/255)
                
                if isExpanded, let image = image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .figmaLayerBlur(radius: 94)
                        .opacity(0.26)
                        .transition(.opacity)
                }
            }
        }
        .onTapGesture {
            if !isExpanded {
                onToggle()
            }
        }
    }
}"""
content = re.sub(r'struct ArticleRowView: View \{.*?\n// Custom modifier to simulate', new_row + '\n\n// Custom modifier to simulate', content, flags=re.DOTALL)

with open("/Users/nabhi/Desktop/Projects/Beanstalk/Beanstalk/Beanstalk/FeedView.swift", "w") as f:
    f.write(content)

