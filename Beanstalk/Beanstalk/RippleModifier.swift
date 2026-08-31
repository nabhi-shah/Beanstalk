import SwiftUI

struct RippleModifier: ViewModifier {
    var rippleColor: Color
    var touchLocation: CGPoint?
    var isPressed: Bool
    
    @State private var progress: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .visualEffect { viewContent, geometryProxy in
                let center = touchLocation ?? CGPoint(x: geometryProxy.size.width / 2, y: geometryProxy.size.height / 2)
                return viewContent.colorEffect(
                    ShaderLibrary.default.lightRipple(
                        .float2(center),
                        .float(progress),
                        .float2(geometryProxy.size),
                        .color(rippleColor)
                    )
                )
            }
            .onChange(of: isPressed) { oldValue, newValue in
                if newValue {
                    progress = 0.0
                    withAnimation(.easeOut(duration: 1.5)) {
                        progress = 1.0
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
