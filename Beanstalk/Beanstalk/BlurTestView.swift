import SwiftUI

struct BlurTestView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 80) {
                
                // Example 1: Standard SwiftUI Blur
                VStack {
                    Text("Standard SwiftUI .blur()")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(.bottom, 10)
                    
                    ZStack {
                        // A hard bounding box to show where the frame ends
                        Rectangle()
                            .stroke(Color.gray, style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .frame(width: 200, height: 100)
                        
                        // The "Image" (a real photo)
                        AsyncImage(url: URL(string: "https://static01.nyt.com/images/2026/08/23/multimedia/23data-centers-promo-hp-hltm/23data-centers-promo-hp-hltm-mediumSquareAt3X.jpg")) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Color.gray
                            }
                        }
                        .frame(width: 200, height: 100)
                        // IMPORTANT: Clipping the image to its frame before blurring
                        // This simulates an image constrained by a container
                        .clipped()
                        .blur(radius: 64)
                    }
                    
                    Text("Notice how the blur stops entirely at the dashed border (the layout frame).")
                        .foregroundColor(.gray)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                        .padding(.horizontal, 40)
                }
                
                // Example 2: Figma Layer Blur
                VStack {
                    Text("Custom .figmaLayerBlur()")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(.bottom, 10)
                    
                    ZStack {
                        // A hard bounding box to show where the frame ends
                        Rectangle()
                            .stroke(Color.gray, style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .frame(width: 200, height: 100)
                        
                        // The "Image" (a real photo)
                        AsyncImage(url: URL(string: "https://static01.nyt.com/images/2026/08/23/multimedia/23data-centers-promo-hp-hltm/23data-centers-promo-hp-hltm-mediumSquareAt3X.jpg")) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Color.gray
                            }
                        }
                        .frame(width: 200, height: 100)
                        .clipped()
                        .figmaLayerBlur(radius: 20)
                    }
                    
                    Text("Notice how the blur beautifully bleeds outside the dashed border into the surrounding space!")
                        .foregroundColor(.gray)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                        .padding(.horizontal, 40)
                }
            }
        }
    }
}

#Preview {
    BlurTestView()
}
