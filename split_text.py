with open("Beanstalk/Beanstalk/FeedView.swift", "r") as f:
    content = f.read()

import re

# 1. Add showExpandedContent state
content = content.replace("@State private var showChevrons: Bool = false", "@State private var showChevrons: Bool = false\n    @State private var showExpandedContent: Bool = false")

# 2. Update onChange
old_onchange = """.onChange(of: isExpanded) { oldValue, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showChevrons = true
                    }
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    showChevrons = false
                }
            }
        }"""
new_onchange = """.onChange(of: isExpanded) { oldValue, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showChevrons = true
                        showExpandedContent = true
                    }
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    showChevrons = false
                    showExpandedContent = false
                }
            }
        }"""
content = content.replace(old_onchange, new_onchange)

# 3. Add text views
new_views = """
    @ViewBuilder
    private func authorInfoView() -> some View {
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
    }
    
    @ViewBuilder
    private func unexpandedTextContent() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            authorInfoView()
            
            Text(article.title)
                .font(.custom("InclusiveSans-Regular", size: 18))
                .foregroundColor(.textDark)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func expandedTextContent() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            authorInfoView()
            
            Text(article.title)
                .font(.custom("InclusiveSans-Regular", size: 18))
                .foregroundColor(.textDark)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
            
            Text(article.aiSummary)
                .foregroundColor(Color(white: 0.35))
                .lineSpacing(4)
                .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .padding(.bottom, 64)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
"""
content = content.replace("private func cardContent(image: Image?) -> some View {", new_views + "\n    private func cardContent(image: Image?) -> some View {")

# 4. Replace text content in cardContent
old_text_content_regex = r'// Text Content\s*VStack\(alignment: \.leading, spacing: 12\) \{.*?\.frame\(maxWidth: \.infinity, alignment: \.leading\)'

new_text_content = """// Text Content
                ZStack(alignment: .topLeading) {
                    if !isExpanded {
                        unexpandedTextContent()
                            .transition(.opacity)
                    }
                    if showExpandedContent {
                        expandedTextContent()
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }"""

content = re.sub(old_text_content_regex, new_text_content, content, flags=re.DOTALL)

with open("Beanstalk/Beanstalk/FeedView.swift", "w") as f:
    f.write(content)

