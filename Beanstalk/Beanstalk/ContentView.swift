import SwiftUI

struct ContentView: View {
    @Binding var appState: AppState
    var animationNamespace: Namespace.ID

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
                .matchedGeometryEffect(id: "logo", in: animationNamespace)
                .padding(.top, 60)
                .padding(.bottom, 16)
                .blur(radius: focusedField != nil ? 10.0 : 0.0)
                .opacity(focusedField != nil ? 0.0 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: focusedField)

            // Tabs
            GeometryReader { proxy in
                HStack(spacing: 12) {
                    Text("Login")
                        .font(.custom("InclusiveSans-Regular", size: 16))
                        .foregroundColor(isLogin ? .white : .textDark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        
                    Text("Signup")
                        .font(.custom("InclusiveSans-Regular", size: 16))
                        .foregroundColor(!isLogin ? .white : .textDark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .background(
                    GooeyTabBackground(isLogin: isLogin)
                        .rippleEffect(color: Color.brandGreen.opacity(0.4)) { location in
                            let isLeft = location.x < proxy.size.width / 2
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                isLogin = isLeft
                            }
                        }
                )
            }
            .frame(height: 48) // Fixed height to prevent GeometryReader from collapsing

            // Form
            VStack(spacing: 16) {
                // Email Field
                InputField(
                    placeholder: "Email address",
                    text: $email,
                    isFocused: focusedField == .email
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
                        isFocused: focusedField == .password
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
            Text(isLogin ? "Login" : "Signup")
                .font(.custom("InclusiveSans-Regular", size: 18))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Color.brandGreen.rippleEffect(color: Color.white.opacity(0.3)) { _ in
                        if isLogin {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                appState = .onboarding
                            }
                        }
                    }
                )
                .clipShape(Capsule())
            .padding(.top, 8)

            // (Social Logins removed as requested)

            Spacer()
        }
        .padding(.horizontal, 24)
        .background(
            Color.appBackground
                .ignoresSafeArea()
                .onTapGesture {
                    focusedField = nil
                }
        )
        .offset(y: focusedField != nil ? -60 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: focusedField)
    }
}

struct GooeyTabBackground: View {
    var isLogin: Bool
    
    var body: some View {
        GeometryReader { proxy in
            let spacing: CGFloat = 12
            let tabWidth = (proxy.size.width - spacing) / 2
            let tabHeight = proxy.size.height
            
            ZStack(alignment: .leading) {
                // Inactive backgrounds
                HStack(spacing: spacing) {
                    Capsule().fill(Color.secondaryBackground)
                        .frame(width: tabWidth)
                    Capsule().fill(Color.secondaryBackground)
                        .frame(width: tabWidth)
                }
                
                // Gooey active fluid mask
                Color.textDark
                    .mask(
                        ZStack(alignment: .topLeading) {
                            Color.black // Black becomes transparent
                            
                            // Anchor 1 (Login)
                            Capsule()
                                .fill(Color.white) // White becomes opaque
                                .frame(width: tabWidth, height: tabHeight)
                                .offset(x: 0)
                            
                            // Anchor 2 (Signup)
                            Capsule()
                                .fill(Color.white)
                                .frame(width: tabWidth, height: tabHeight)
                                .offset(x: tabWidth + spacing)
                            
                            // The traveling fluid bridge
                            Color.clear
                                .modifier(FluidBridgeModifier(
                                    progress: isLogin ? 0 : 1,
                                    tabWidth: tabWidth,
                                    tabHeight: tabHeight,
                                    spacing: spacing,
                                    color: .white
                                ))
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .padding(-20) // Give room for blur bleed
                        .blur(radius: 8)
                        .contrast(20)
                        .luminanceToAlpha()
                        .padding(20) // Restore exact alignment
                    )
            }
        }
    }
}

struct FluidBridgeModifier: ViewModifier, Animatable {
    var progress: CGFloat
    var tabWidth: CGFloat
    var tabHeight: CGFloat
    var spacing: CGFloat
    var color: Color
    
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
            .fill(color)
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
    let icon: Icon

    init(
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        isFocused: Bool,
        @ViewBuilder icon: () -> Icon
    ) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.isFocused = isFocused
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
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(isFocused ? Color.linkGreen : Color.clear, lineWidth: 3)
                .animation(.easeInOut(duration: 0.3), value: isFocused)
        )
    }
}

#Preview {
    @Previewable @Namespace var namespace
    ContentView(appState: .constant(.login), animationNamespace: namespace)
}
