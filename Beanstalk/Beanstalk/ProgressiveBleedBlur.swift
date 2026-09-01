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
            // Calculate step size
            let bandSize = (1.0 - offset) / CGFloat(steps)
            
            // 0. Base Unblurred Layer
            // It is fully opaque up to the offset, then fades out into the first blur layer.
            content
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0.0),
                            .init(color: .black, location: offset),
                            .init(color: .clear, location: offset + bandSize)
                        ],
                        startPoint: startPoint(for: direction),
                        endPoint: endPoint(for: direction)
                    )
                )
            
            // 1...N Blurred Layers
            // Each layer is a specific band that fades in from the previous layer, peaks, and fades out into the next layer.
            ForEach(1...steps, id: \.self) { step in
                let progress = CGFloat(step) / CGFloat(steps)
                let currentRadius = radius * pow(progress, 1.5) // Non-linear blur scale
                
                let prevLocation = offset + (1.0 - offset) * CGFloat(step - 1) / CGFloat(steps)
                let currLocation = offset + (1.0 - offset) * progress
                let nextLocation = offset + (1.0 - offset) * CGFloat(step + 1) / CGFloat(steps)
                
                content
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: prevLocation),
                                .init(color: .black, location: currLocation),
                                .init(color: step == steps ? .black : .clear, location: step == steps ? 1.0 : nextLocation)
                            ],
                            startPoint: startPoint(for: direction),
                            endPoint: endPoint(for: direction)
                        )
                    )
                    .padding(radius * 2) // padding for organic bleed
                    .blur(radius: currentRadius)
                    .padding(-radius * 2)
            }
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


