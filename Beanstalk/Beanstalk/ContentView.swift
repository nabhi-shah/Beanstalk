import SwiftUI

struct ContentView: View {
    @State private var isLogin = true
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case email
        case password
    }

    struct BlurTransitionModifier: ViewModifier {
        let isBlurred: Bool
        func body(content: Content) -> some View {
            content
                .blur(radius: isBlurred ? 10 : 0)
                .opacity(isBlurred ? 0 : 1)
        }
    }

    var body: some View {
        VStack(spacing: 32) {
            Image("BeanstalkLogo")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(height: 36)
                .padding(.top, 60)
                .padding(.bottom, 16)
                .blur(radius: focusedField != nil ? 10.0 : 0.0)
                .opacity(focusedField != nil ? 0.0 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: focusedField)

            // Tabs
            HStack(spacing: 12) {
                TabButton(title: "Login", isActive: isLogin) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        isLogin = true
                    }
                }
                TabButton(title: "Signup", isActive: !isLogin) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        isLogin = false
                    }
                }
            }
            .background(GooeyTabBackground(isLogin: isLogin).rippleEffect(color: Color.brandGreen.opacity(0.4)))

            // Form
            VStack(spacing: 16) {
                // Email Field
                InputField(
                    placeholder: "Email address",
                    text: $email,
                    isFocused: focusedField == .email,
                    onTap: { focusedField = .email }
                ) {
                    Image("phosphor_at")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(focusedField == .email ? .linkGreen : .textSecondary)
                }
                .focused($focusedField, equals: .email)

                // Password Field
                if isLogin {
                    InputField(
                        placeholder: "Password",
                        text: $password,
                        isSecure: true,
                        isFocused: focusedField == .password,
                        onTap: { focusedField = .password }
                    ) {
                        Image("phosphor_lock")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(focusedField == .password ? .linkGreen : .textSecondary)
                    }
                    .focused($focusedField, equals: .password)
                    .transition(AnyTransition.modifier(
                        active: BlurTransitionModifier(isBlurred: true),
                        identity: BlurTransitionModifier(isBlurred: false)
                    ))
                }
            }
            .padding(.top, 8)

            // Forgot Password
            if isLogin {
                Button("Forgot Password") {
                    // Action
                }
                .font(.custom("InclusiveSans-Regular", size: 15))
                .foregroundColor(.linkGreen)
                .padding(.top, 8)
                .transition(AnyTransition.modifier(
                    active: BlurTransitionModifier(isBlurred: true),
                    identity: BlurTransitionModifier(isBlurred: false)
                ))
            }

            // Submit Button
            Button(action: {
                // Action
            }) {
                Text(isLogin ? "Login" : "Signup")
                    .font(.custom("InclusiveSans-Regular", size: 18))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.brandGreen.rippleEffect(color: Color.white.opacity(0.3)))
                    .clipShape(Capsule())
            }
            .padding(.top, 8)

            // (Social Logins removed as requested)

            Spacer()
        }
        .padding(.horizontal, 24)
        .background(Color.appBackground)
        .onTapGesture {
            focusedField = nil
        }
    }
}

struct GooeyTabBackground: View {
    var isLogin: Bool
    
    var body: some View {
        GeometryReader { proxy in
            let spacing: CGFloat = 12
            let tabWidth = (proxy.size.width - spacing) / 2
            let tabHeight = proxy.size.height
            
            ZStack {
                // Inactive backgrounds
                HStack(spacing: spacing) {
                    Capsule().fill(Color.secondaryBackground)
                        .frame(width: tabWidth)
                    Capsule().fill(Color.secondaryBackground)
                        .frame(width: tabWidth)
                }
                
                // Gooey active fluid
                Canvas { context, size in
                    #if !targetEnvironment(simulator)
                    context.addFilter(.alphaThreshold(min: 0.5, color: .black))
                    context.addFilter(.blur(radius: 12))
                    #endif
                    
                    context.drawLayer { ctx in
                        if let resolved = context.resolveSymbol(id: 1) {
                            ctx.draw(resolved, at: CGPoint(x: size.width / 2, y: size.height / 2))
                        }
                    }
                } symbols: {
                    ZStack(alignment: .topLeading) {
                        // Anchor 1 (Login)
                        Capsule()
                            .fill(Color.black)
                            .frame(width: isLogin ? tabWidth : 0, height: isLogin ? tabHeight : 0)
                            .position(x: tabWidth / 2, y: tabHeight / 2)
                        
                        // Anchor 2 (Signup)
                        Capsule()
                            .fill(Color.black)
                            .frame(width: !isLogin ? tabWidth : 0, height: !isLogin ? tabHeight : 0)
                            .position(x: tabWidth + spacing + tabWidth / 2, y: tabHeight / 2)
                        
                        // The traveling fluid bridge
                        Color.clear
                            .modifier(FluidBridgeModifier(
                                progress: isLogin ? 0 : 1,
                                tabWidth: tabWidth,
                                tabHeight: tabHeight,
                                spacing: spacing
                            ))
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                    .tag(1)
                }
                .padding(-30) // Adds invisible breathing room so the spring bounce & blur aren't cropped
                .colorMultiply(Color.textDark)
            }
        }
    }
}

struct FluidBridgeModifier: ViewModifier, Animatable {
    var progress: CGFloat
    var tabWidth: CGFloat
    var tabHeight: CGFloat
    var spacing: CGFloat
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func body(content: Content) -> some View {
        let sinProgress = sin(progress * .pi)
        
        // Fluid gets thinner as it stretches
        let currentHeight = tabHeight * (1 - sinProgress * 0.6)
        
        // Fluid stretches across the gap
        let currentWidth = tabWidth + (sinProgress * spacing * 2.5)
        
        let startCenterX = tabWidth / 2
        let endCenterX = tabWidth + spacing + tabWidth / 2
        let currentCenterX = startCenterX + progress * (endCenterX - startCenterX)
        
        return Capsule()
            .fill(Color.black)
            .frame(width: currentWidth, height: currentHeight)
            .position(x: currentCenterX, y: tabHeight / 2)
    }
}

struct TabButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("InclusiveSans-Regular", size: 16))
                .foregroundColor(isActive ? .white : .textDark)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .contentShape(Capsule())
        }
    }
}

struct SocialButton<Icon: View>: View {
    let title: String
    let icon: Icon
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                icon
                    .frame(width: 20, height: 20)
                Text(title)
                    .font(.custom("InclusiveSans-Regular", size: 16))
            }
            .foregroundColor(.textDark)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.secondaryBackground.rippleEffect(color: Color.brandGreen.opacity(0.25)))
            .clipShape(Capsule())
        }
    }
}

struct InputField<Icon: View>: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var isFocused: Bool
    var onTap: (() -> Void)? = nil
    let icon: Icon

    init(
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        isFocused: Bool,
        onTap: (() -> Void)? = nil,
        @ViewBuilder icon: () -> Icon
    ) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.isFocused = isFocused
        self.onTap = onTap
        self.icon = icon()
    }

    var body: some View {
        HStack(spacing: 12) {
            icon
                .animation(.easeInOut(duration: 0.3), value: isFocused)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.custom("InclusiveSans-Regular", size: 16))
                    .foregroundColor(.textDark)
                    .autocapitalization(.none)
            } else {
                TextField(placeholder, text: $text)
                    .font(.custom("InclusiveSans-Regular", size: 16))
                    .foregroundColor(.textDark)
                    .autocapitalization(.none)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.secondaryBackground)
        .rippleEffect(color: Color.brandGreen.opacity(0.25))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(isFocused ? Color.linkGreen : Color.clear, lineWidth: 3)
                .animation(.easeInOut(duration: 0.3), value: isFocused)
        )
        .contentShape(Capsule())
        .onTapGesture {
            onTap?()
        }
    }
}

#Preview {
    ContentView()
}
