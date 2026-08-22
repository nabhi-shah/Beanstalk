import SwiftUI

struct RippleModifier: ViewModifier {
    var rippleColor: Color = .white
    var action: ((CGPoint) -> Void)? = nil
    
    @State private var touchLocation: CGPoint = .zero
    @State private var progress: CGFloat = 1.0
    @State private var isTouching: Bool = false
    @GestureState private var isPressing: Bool = false
    
    func body(content: Content) -> some View {
        content
            .buttonStyle(PlainButtonStyle())
            .visualEffect { viewContent, geometryProxy in
                viewContent.colorEffect(
                    ShaderLibrary.default.lightRipple(
                        .float2(touchLocation),
                        .float(progress),
                        .float2(geometryProxy.size),
                        .color(rippleColor)
                    )
                )
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressing) { _, state, _ in
                        state = true
                    }
                    .onChanged { value in
                        if !isTouching {
                            isTouching = true
                            touchLocation = value.location
                            progress = 0.0
                            
                            withAnimation(.easeOut(duration: 1.5)) {
                                progress = 1.0
                            }
                        }
                    }
                    .onEnded { value in
                        isTouching = false
                        // Only trigger action if it was a tap, not a scroll
                        let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                        if distance < 10 {
                            action?(value.location)
                        }
                    }
            )
            .onChange(of: isPressing) { oldValue, newValue in
                if !newValue {
                    isTouching = false
                }
            }
    }
}

extension View {
    /// Applies a light ripple effect on touch.
    func rippleEffect(color: Color = .white, action: ((CGPoint) -> Void)? = nil) -> some View {
        self.modifier(RippleModifier(rippleColor: color, action: action))
    }
}
