import SwiftUI

struct RippleModifier: ViewModifier {
    var rippleColor: Color
    var touchLocation: CGPoint?
    var isPressed: Bool
    
    @State private var scale: CGFloat = 0.0
    @State private var opacity: Double = 0.0
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    let center = touchLocation ?? CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                    // The radius must cover the furthest corner from any touch point. 
                    // 1.5x the maximum dimension guarantees coverage.
                    let radius = max(geo.size.width, geo.size.height) * 1.5
                    
                    if isAnimating {
                        Circle()
                            .fill(rippleColor)
                            .frame(width: radius * 2, height: radius * 2)
                            .position(center)
                            .scaleEffect(scale)
                            .opacity(opacity)
                    }
                }
                .clipped() // Ensure the ripple doesn't overflow the view's bounds
                .allowsHitTesting(false)
            )
            .onChange(of: isPressed) { oldValue, newValue in
                if newValue {
                    isAnimating = true
                    scale = 0.0
                    opacity = 1.0
                    
                    withAnimation(.easeOut(duration: 0.6)) {
                        scale = 1.0
                        opacity = 0.0
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        isAnimating = false
                    }
                }
            }
    }
}

struct RippleButtonStyle: ButtonStyle {
    var rippleColor: Color
    
    @State private var touchLocation: CGPoint?
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modifier(RippleModifier(rippleColor: rippleColor, touchLocation: touchLocation, isPressed: configuration.isPressed))
            .background(
                TouchLocatingView { location in
                    if !configuration.isPressed {
                        touchLocation = location
                    }
                }
            )
    }
}

struct TouchLocatingView: UIViewRepresentable {
    var onUpdate: (CGPoint) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = TouchLocatingUIView()
        view.onUpdate = onUpdate
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    class TouchLocatingUIView: UIView {
        var onUpdate: ((CGPoint) -> Void)?
        
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            // hitTest is called multiple times, capture the location
            onUpdate?(point)
            return nil // Do not intercept touches!
        }
    }
}

extension View {
    func rippleEffect(color: Color = .white, isPressed: Bool = false) -> some View {
        self.modifier(RippleModifier(rippleColor: color, touchLocation: nil, isPressed: isPressed))
    }
}
