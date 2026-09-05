import Foundation
import SwiftUI
import UIKit

struct Article: Identifiable {
    let id: UUID
    let publication: String
    let author: String
    let date: String
    let title: String
    let content: String
    let aiSummary: String
    let thumbnailURL: URL?
    let attributedContent: AttributedString
    let isLeadingDark: Bool?
    let isTrailingDark: Bool?
    
    var isDarkHeader: Bool? {
        if let l = isLeadingDark, let t = isTrailingDark {
            return l == t ? l : nil
        }
        return isLeadingDark ?? isTrailingDark
    }
    
    init(
        id: UUID = UUID(),
        publication: String,
        author: String,
        date: String,
        title: String,
        content: String,
        aiSummary: String,
        thumbnailURLString: String? = nil,
        isDarkHeader: Bool? = nil,
        isLeadingDark: Bool? = nil,
        isTrailingDark: Bool? = nil
    ) {
        self.id = id
        self.publication = publication
        self.author = author
        self.date = date
        self.title = title
        self.content = content
        self.aiSummary = aiSummary
        self.isLeadingDark = isLeadingDark ?? isDarkHeader
        self.isTrailingDark = isTrailingDark ?? isDarkHeader
        if let urlString = thumbnailURLString, !urlString.isEmpty {
            self.thumbnailURL = URL(string: urlString)
        } else {
            self.thumbnailURL = nil
        }
        
        if let parsedStr = try? AttributedString(markdown: content) {
            var str = parsedStr
            var breakIndices = [AttributedString.Index]()
            for (intent, range) in str.runs[\.presentationIntent] {
                if let intent = intent {
                    if range.upperBound < str.endIndex {
                        breakIndices.append(range.upperBound)
                    }
                    for component in intent.components {
                        if case .header(let level) = component.kind {
                            let size: CGFloat = level == 1 ? 24 : (level == 2 ? 22 : 20)
                            str[range].font = .system(size: size, weight: .bold)
                        }
                    }
                }
            }
            for index in breakIndices.sorted(by: >) {
                str.insert(AttributedString("\n\n"), at: index)
            }
            self.attributedContent = str
        } else {
            self.attributedContent = AttributedString(content)
        }
    }
}

import Combine

@MainActor
final class RemoteImageManager {
    static let shared = RemoteImageManager()
    
    private let cache = NSCache<NSURL, UIImage>()
    private var inFlight = [URL: Task<UIImage?, Never>]()
    
    init() {
        cache.countLimit = 100
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB
    }
    
    func image(for url: URL?) -> UIImage? {
        guard let url = url else { return nil }
        return cache.object(forKey: url as NSURL)
    }
    
    func load(url: URL?) async -> UIImage? {
        guard let url = url else { return nil }
        
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }
        
        if let existing = inFlight[url] {
            return await existing.value
        }
        
        let task = Task<UIImage?, Never> {
            var request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 15)
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148", forHTTPHeaderField: "User-Agent")
            request.setValue("image/webp,image/avif,image/jpeg,image/png,image/*;q=0.8,*/*;q=0.5", forHTTPHeaderField: "Accept")
            if url.host?.contains("nyt.com") == true {
                request.setValue("https://www.nytimes.com/", forHTTPHeaderField: "Referer")
            }
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResp = response as? HTTPURLResponse, (200...299).contains(httpResp.statusCode) {
                    let decodedImage = await Task.detached(priority: .userInitiated) { () -> UIImage? in
                        UIImage(data: data)
                    }.value
                    if let uiImage = decodedImage {
                        self.cache.setObject(uiImage, forKey: url as NSURL)
                        return uiImage
                    }
                }
            } catch {
                // Return nil on error
            }
            return nil
        }
        
        inFlight[url] = task
        let result = await task.value
        inFlight.removeValue(forKey: url)
        return result
    }
}
