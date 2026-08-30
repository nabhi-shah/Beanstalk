import SwiftUI

enum MainTab: Hashable {
    case home, search, saved, profile
}
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct FeedView: View {
    @Binding var appState: AppState
    var animationNamespace: Namespace.ID
    
    @State private var selectedTab: MainTab = .home
    @State private var minimizeProgress: Double = 0
    
    var body: some View {
        NavigationStack {
            UnionTabView(selection: $selectedTab, tabs: [.home, .search, .saved, .profile], minimizeProgress: minimizeProgress) {
                FeedContentView(animationNamespace: animationNamespace, minimizeProgress: $minimizeProgress).unionTab(MainTab.home)
                
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
    var animationNamespace: Namespace.ID
    @Binding var minimizeProgress: Double
    @State private var lastOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView {
                GeometryReader { proxy in
                    Color.clear.preference(key: ScrollOffsetKey.self, value: proxy.frame(in: .named("scroll")).minY)
                }
                .frame(height: 0)
                
                LazyVStack(spacing: 16) {
                    ForEach(MockData.articles) { article in
                        NavigationLink(destination: ArticleDetailView(article: article)) {
                            ArticleRowView(article: article)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 64)
                .padding(.bottom, 120) // Space for TabBar
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { offset in
                let delta = lastOffset - offset
                lastOffset = offset
                
                if offset >= 0 {
                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                        minimizeProgress = 0
                    }
                } else {
                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                        let newProgress = minimizeProgress + Double(delta / 100.0)
                        minimizeProgress = min(max(newProgress, 0), 1)
                    }
                }
            }
            
            VStack {
                Spacer()
                ProgressiveBlurView(height: 140, edge: .bottom)
            }
            .ignoresSafeArea()

            ProgressiveBlurView(height: 120, edge: .top)

            // Custom Header
            HStack {
                Spacer()
                Image("BeanstalkLogo")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
                    .matchedGeometryEffect(id: "logo", in: animationNamespace)
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                Spacer()
            }
        }
    }
}

struct ArticleRowView: View {
    let article: Article
    @StateObject private var loader = ArticleImageLoader()
    
    var body: some View {
        Group {
            if let url = article.thumbnailURL {
                cardContent(image: loader.processedImage, originalImage: loader.originalImage)
                    .onAppear {
                        // Calculate width dynamically
                        let cardWidth = UIScreen.main.bounds.width - 24
                        loader.load(url: url, size: CGSize(width: cardWidth, height: 280))
                    }
            } else {
                cardContent(image: nil, originalImage: nil)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .stroke(Color(red: 223/255, green: 223/255, blue: 223/255), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    @ViewBuilder
    private func cardContent(image: Image?, originalImage: Image?) -> some View {
        VStack(spacing: 0) {
            // Thumbnail Section
            Color.clear
                .frame(height: 280)
                .overlay(
                    Group {
                        if let image = image {
                            // This image already has CIMaskedVariableBlur baked in!
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .mask( // Blend into content section
                                    LinearGradient(
                                        stops: [
                                            .init(color: .white, location: 0.95),
                                            .init(color: .clear, location: 1.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        } else {
                            Rectangle().fill(Color.clear)
                        }
                    }
                )
                .clipped()
            
            // Content Section
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    // Publication Logo
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
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            ZStack {
                Color(red: 245/255, green: 245/255, blue: 245/255) // #F5F5F5
                
                if let orig = originalImage {
                    orig
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .blur(radius: 94)
                        .opacity(0.26)
                }
            }
            .clipped()
        )
    }
}

#Preview {
    @Previewable @Namespace var namespace
    FeedView(appState: .constant(.feed), animationNamespace: namespace)
}
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()
    
    func get(url: URL, size: CGSize) -> UIImage? {
        let key = "\(url.absoluteString)_\(size.width)_\(size.height)" as NSString
        return cache.object(forKey: key)
    }
    
    func set(_ image: UIImage, for url: URL, size: CGSize) {
        let key = "\(url.absoluteString)_\(size.width)_\(size.height)" as NSString
        cache.setObject(image, forKey: key)
    }
    
    func getOriginal(url: URL) -> UIImage? {
        return cache.object(forKey: url.absoluteString as NSString)
    }
    
    func setOriginal(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url.absoluteString as NSString)
    }
}

class ArticleImageLoader: ObservableObject {
    @Published var processedImage: Image?
    @Published var originalImage: Image?
    
    private var url: URL?
    private var size: CGSize = .zero
    private let context = CIContext(options: [.useSoftwareRenderer: false])
    
    func load(url: URL, size: CGSize) {
        guard size.width > 0 && size.height > 0 else { return }
        self.url = url
        self.size = size
        
        if let cachedProcessed = ImageCache.shared.get(url: url, size: size),
           let cachedOriginal = ImageCache.shared.getOriginal(url: url) {
            self.processedImage = Image(uiImage: cachedProcessed)
            self.originalImage = Image(uiImage: cachedOriginal)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self, let data = data, let uiImage = UIImage(data: data) else { return }
            
            ImageCache.shared.setOriginal(uiImage, for: url)
            
            DispatchQueue.global(qos: .userInitiated).async {
                if let processed = self.process(uiImage: uiImage, size: size) {
                    ImageCache.shared.set(processed, for: url, size: size)
                    DispatchQueue.main.async {
                        if self.url == url && self.size == size {
                            self.originalImage = Image(uiImage: uiImage)
                            self.processedImage = Image(uiImage: processed)
                        }
                    }
                }
            }
        }.resume()
    }
    
    private func process(uiImage: UIImage, size: CGSize) -> UIImage? {
        let aspectWidth = size.width / uiImage.size.width
        let aspectHeight = size.height / uiImage.size.height
        let scale = max(aspectWidth, aspectHeight)
        
        let scaledWidth = uiImage.size.width * scale
        let scaledHeight = uiImage.size.height * scale
        
        let rect = CGRect(
            x: (size.width - scaledWidth) / 2.0,
            y: (size.height - scaledHeight) / 2.0,
            width: scaledWidth,
            height: scaledHeight
        )
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let cropped = renderer.image { _ in
            uiImage.draw(in: rect)
        }
        
        guard let ciImage = CIImage(image: cropped) else { return nil }
        
        let gradient = CIFilter.linearGradient()
        gradient.color0 = CIColor.white
        gradient.color1 = CIColor.clear
        gradient.point0 = CGPoint(x: 0, y: 0)
        gradient.point1 = CGPoint(x: 0, y: size.height * 0.25)
        
        guard let mask = gradient.outputImage else { return nil }
        
        let blur = CIFilter.maskedVariableBlur()
        blur.inputImage = ciImage
        blur.mask = mask
        blur.radius = 94
        
        guard let output = blur.outputImage,
              let cgImage = context.createCGImage(output, from: CGRect(origin: .zero, size: size)) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
}
