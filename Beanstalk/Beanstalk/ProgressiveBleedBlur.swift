import SwiftUI

public struct ProgressiveBleedBlur: ViewModifier {
    public var radius: CGFloat
    public var offset: CGFloat // Value between 0 and 1
    public var direction: Edge
    public var steps: Int
    
    public init(radius: CGFloat, offset: CGFloat = 0.0, direction: Edge = .bottom, steps: Int = 12) {
        self.radius = radius
        self.offset = offset
        self.direction = direction
        self.steps = steps
    }
    
    public func body(content: Content) -> some View {
        ZStack {
            // 0. Base Unblurred Layer
            content
            
            // 1...N Blurred Layers
            ForEach(1...steps, id: \.self) { step in
                let progress = CGFloat(step) / CGFloat(steps)
                let currentRadius = radius * pow(progress, 1.5)
                
                let prevLocation = offset + (1.0 - offset) * CGFloat(step - 1) / CGFloat(steps)
                let currLocation = offset + (1.0 - offset) * progress
                
                content
                    // Blur first so the full image energy is preserved and spreads outward
                    .blur(radius: currentRadius)
                    .mask(
                        // We use a custom extension mask that exactly covers the image with the gradient,
                        // and extends infinitely outward with solid black to prevent clipping the bleed.
                        bleedMask(prevLocation: prevLocation, currLocation: currLocation)
                    )
            }
        }
    }
    
    @ViewBuilder
    private func bleedMask(prevLocation: CGFloat, currLocation: CGFloat) -> some View {
        let bleedAmount: CGFloat = radius * 4 // Enough space to catch all blur bleed
        let gradient = LinearGradient(
            stops: [
                .init(color: .clear, location: prevLocation),
                .init(color: .black, location: currLocation)
            ],
            startPoint: startPoint(for: direction),
            endPoint: endPoint(for: direction)
        )
        
        switch direction {
        case .bottom:
            VStack(spacing: 0) {
                gradient
                Color.black.frame(height: bleedAmount)
            }
            .padding(.bottom, -bleedAmount)
        case .top:
            VStack(spacing: 0) {
                Color.black.frame(height: bleedAmount)
                gradient
            }
            .padding(.top, -bleedAmount)
        case .leading:
            HStack(spacing: 0) {
                Color.black.frame(width: bleedAmount)
                gradient
            }
            .padding(.leading, -bleedAmount)
        case .trailing:
            HStack(spacing: 0) {
                gradient
                Color.black.frame(width: bleedAmount)
            }
            .padding(.trailing, -bleedAmount)
        }
    }
    
    private func startPoint(for edge: Edge) -> UnitPoint {
        switch edge {
        case .top: return .bottom
        case .bottom: return .top
        case .leading: return .trailing
        case .trailing: return .leading
        }
    }
    
    private func endPoint(for edge: Edge) -> UnitPoint {
        switch edge {
        case .top: return .top
        case .bottom: return .bottom
        case .leading: return .leading
        case .trailing: return .trailing
        }
    }
}

public extension View {
    func progressiveBleedBlur(radius: CGFloat, offset: CGFloat = 0.0, direction: Edge = .bottom, steps: Int = 12) -> some View {
        modifier(ProgressiveBleedBlur(radius: radius, offset: offset, direction: direction, steps: steps))
    }
}
