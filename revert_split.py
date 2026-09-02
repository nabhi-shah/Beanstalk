import re

with open("Beanstalk/Beanstalk/FeedView.swift", "r") as f:
    content = f.read()

# 1. Remove state
content = content.replace("@State private var showChevrons: Bool = false\n    @State private var showExpandedContent: Bool = false", "@State private var showChevrons: Bool = false")

# 2. Revert onChange
old_onchange = """.onChange(of: isExpanded) { oldValue, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeIn(duration: 0.2)) {
                        showActions = true
                        showExpandedContent = true
                    }
                }
            } else {
                showActions = false
                showExpandedContent = false
                if frontCardIndex != 0 {"""
new_onchange = """.onChange(of: isExpanded) { oldValue, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeIn(duration: 0.2)) {
                        showActions = true
                    }
                }
            } else {
                showActions = false
                if frontCardIndex != 0 {"""
content = content.replace(old_onchange, new_onchange)

# 3. Remove text views
views_regex = r'    private func authorInfoView\(\) -> some View \{.*?    private func cardContent\(image: Image\?\) -> some View \{'
content = re.sub(views_regex, '    private func cardContent(image: Image?) -> some View {', content, flags=re.DOTALL)

# 4. Restore cardContent text block
zstack_regex = r'// Text Content\s*ZStack\(alignment: \.topLeading\) \{.*?expandedTextContent\(\)\s*\.transition\(\.opacity\.combined\(with: \.move\(edge: \.bottom\)\)\)\s*\}\s*\}'
restored_text = """// Text Content
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
                        Text(article.aiSummary)
                            .foregroundColor(Color(white: 0.35))
                            .lineSpacing(4)
                            .padding(.top, 8)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .padding(.bottom, isExpanded ? 64 : 0) // Extra padding for buttons when expanded
                .frame(maxWidth: .infinity, alignment: .leading)"""
content = re.sub(zstack_regex, restored_text, content, flags=re.DOTALL)

with open("Beanstalk/Beanstalk/FeedView.swift", "w") as f:
    f.write(content)
