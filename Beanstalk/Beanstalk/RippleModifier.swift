import SwiftUI

struct RippleModifier: ViewModifier {
    var rippleColor: Color
    var isPressed: Bool
    
    @State private var progress: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .visualEffect { viewContent, geometryProxy in
                viewContent.colorEffect(
                    ShaderLibrary.default.lightRipple(
                        .float2(CGPoint(x: geometryProxy.size.width / 2, y: geometryProxy.size.height / 2)),
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
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modifier(RippleModifier(rippleColor: rippleColor, isPressed: configuration.isPressed))
    }
}

extension View {
    func rippleEffect(color: Color = .white, isPressed: Bool = false) -> some View {
        self.modifier(RippleModifier(rippleColor: color, isPressed: isPressed))
    }
}
