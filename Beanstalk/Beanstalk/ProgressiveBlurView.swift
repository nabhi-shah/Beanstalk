import SwiftUI

enum BlurEdge {
    case top, bottom
}

struct ProgressiveBlurView: View {
    var height: CGFloat = 100
    var edge: BlurEdge = .top
    
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .opacity(0.6)
            .mask(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .black, location: 0.0),
                        .init(color: .black, location: 0.6),
                        .init(color: .clear, location: 1.0)
                    ]),
                    startPoint: edge == .top ? .top : .bottom,
                    endPoint: edge == .top ? .bottom : .top
                )
            )
            .frame(height: height)
            .ignoresSafeArea()
    }
}
