import SwiftUI
import UIKit

extension EnvironmentValues {
    @Entry var articleDidSave: () -> Void = {}
}

/// An in-app surface that emerges from the top-center camera area.
struct ArticleSavedToast: View {
    let onViewSaved: () -> Void
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var descended = false
    @State private var glassVisible = false
    @State private var expanded = false
    @State private var contentVisible = false
    @State private var opacity = 1.0

    var body: some View {
        GeometryReader { geometry in
            let pillWidth = min(358, geometry.size.width - 32)
            // Safe-area coordinates let the seed sit inside the island region,
            // while the finished pill clears the status bar on every device.
            let originY = geometry.safeAreaInsets.top > 40
                ? 32 - geometry.safeAreaInsets.top : -24

            let dropY: CGFloat = 46
            let currentY = descended ? dropY : originY

            ZStack {
                // Gooey Drop Canvas
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
                    ZStack {
                        // Static dynamic island
                        Capsule()
                            .fill(.black)
                            .frame(width: 126, height: 37)
                            .position(x: geometry.size.width / 2, y: originY)
                        
                        // Dropping shape
                        Color.clear
                            .modifier(ToastDropletModifier(
                                progress: descended ? 1 : 0,
                                originY: originY,
                                dropY: dropY,
                                centerX: geometry.size.width / 2
                            ))
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .tag(1)
                }
                .opacity(glassVisible ? 0 : 1)
                .allowsHitTesting(false)

                // The actual Toast
                HStack(spacing: 10) {
                    Text("Article Saved")
                        .font(.custom("InclusiveSans-Regular", size: 14))
                        .foregroundStyle(.white)

                    Button(action: onViewSaved) {
                        Text("View")
                            .font(.custom("InclusiveSans-Regular", size: 12).weight(.semibold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 10)
                            .frame(minHeight: 28)
                            .background(Color.white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("viewSavedToastButton")
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.leading, 14)
                .padding(.trailing, 6)
                .blur(radius: contentVisible ? 0 : 8)
                .opacity(contentVisible ? 1 : 0)
                .accessibilityHidden(!contentVisible)
                .frame(width: expanded ? nil : 28,
                       height: expanded ? 40 : 28)
                .background(
                    ZStack {
                        Capsule()
                            .fill(.clear)
                            .glassEffect(.regular, in: .capsule)
                            .environment(\.colorScheme, .dark)
                            .opacity(glassVisible ? 1 : 0)

                        Capsule()
                            .fill(.black)
                            .opacity(glassVisible ? 0 : 1)
                    }
                )
                .clipShape(Capsule())
                .shadow(color: .black.opacity(glassVisible ? 0.12 : 0), radius: 18, y: 8)
                .position(x: geometry.size.width / 2, y: currentY)
                .allowsHitTesting(contentVisible)
            }
            .opacity(opacity)
        }
        .task {
            await animateToast()
        }
    }

    @MainActor
    private func animateToast() async {
        do {
            if reduceMotion {
                descended = true
                glassVisible = true
                expanded = true
                contentVisible = true
            } else {
                // Give the initial black circle a rendered frame before moving.
                try await Task.sleep(for: .milliseconds(40))
                withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                    descended = true
                }
                
                // Midway through the drop (about 120ms in), transition to glass
                try await Task.sleep(for: .milliseconds(120))
                withAnimation(.easeInOut(duration: 0.25)) {
                    glassVisible = true
                }
                
                // And begin expanding into the pill shape while it's still settling!
                try await Task.sleep(for: .milliseconds(40))
                withAnimation(.spring(response: 0.52, dampingFraction: 0.76)) {
                    expanded = true
                }
                
                try await Task.sleep(for: .milliseconds(160))
                withAnimation(.easeOut(duration: 0.22)) {
                    contentVisible = true
                }
            }

            AccessibilityNotification.Announcement("Article Saved. View Saved button available.").post()
            try await Task.sleep(for: .seconds(voiceOverEnabled ? 8 : 4))

            withAnimation(.easeOut(duration: 0.18)) {
                contentVisible = false
            }
            if !reduceMotion {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    expanded = false
                }
                try await Task.sleep(for: .milliseconds(180))
                withAnimation(.easeInOut(duration: 0.3)) {
                    glassVisible = false
                    descended = false
                    opacity = 0
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) { opacity = 0 }
            }
            try await Task.sleep(for: .milliseconds(320))
            onDismiss()
        } catch {
            // Re-saving, navigation, or removal cancels the old toast's timeline.
        }
    }
}

private struct ToastDropletModifier: ViewModifier, Animatable {
    var progress: CGFloat
    var originY: CGFloat
    var dropY: CGFloat
    var centerX: CGFloat
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func body(content: Content) -> some View {
        let currentY = originY + (dropY - originY) * progress
        
        return Circle()
            .fill(Color.black)
            .frame(width: 28, height: 28)
            .position(x: centerX, y: currentY)
    }
}
