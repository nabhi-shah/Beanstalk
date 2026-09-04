import SwiftUI

enum SavedTabType: String, CaseIterable {
    case saved = "Saved"
    case annotations = "Annotations"
}

struct SavedGooeyTabView: View {
    @Binding var selectedTab: SavedTabType
    
    private let spacing: CGFloat = 8
    private let tabHeight: CGFloat = 48
    
    var body: some View {
        HStack(spacing: spacing) {
            tabButton(for: .saved)
            tabButton(for: .annotations)
        }
        .background(
            SavedGooeyBackground(
                isSaved: selectedTab == .saved,
                spacing: spacing,
                tabHeight: tabHeight
            )
        )
        .padding(.horizontal, 24)
    }
    
    @ViewBuilder
    private func tabButton(for tab: SavedTabType) -> some View {
        let isSelected = selectedTab == tab
        Button {
            if selectedTab != tab {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    selectedTab = tab
                }
            }
        } label: {
            Text(tab.rawValue)
                .font(.custom("InclusiveSans-Regular", size: 16))
                .foregroundColor(isSelected ? .white : Color.textDark)
                .frame(maxWidth: .infinity)
                .frame(height: tabHeight)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct SavedGooeyBackground: View {
    var isSaved: Bool
    var spacing: CGFloat
    var tabHeight: CGFloat
    
    var body: some View {
        GeometryReader { proxy in
            let tabWidth = (proxy.size.width - spacing) / 2
            
            ZStack {
                // Inactive pill backgrounds
                HStack(spacing: spacing) {
                    Capsule()
                        .fill(Color.secondaryBackground)
                        .frame(width: tabWidth, height: tabHeight)
                    Capsule()
                        .fill(Color.secondaryBackground)
                        .frame(width: tabWidth, height: tabHeight)
                }
                
                // Gooey active fluid bridge using Canvas
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
                        // Anchor 1 (Saved)
                        Capsule()
                            .fill(Color.textDark)
                            .frame(width: isSaved ? tabWidth : 0, height: isSaved ? tabHeight : 0)
                            .position(x: tabWidth / 2, y: tabHeight / 2)
                        
                        // Anchor 2 (Annotations)
                        Capsule()
                            .fill(Color.textDark)
                            .frame(width: !isSaved ? tabWidth : 0, height: !isSaved ? tabHeight : 0)
                            .position(x: tabWidth + spacing + tabWidth / 2, y: tabHeight / 2)
                        
                        // The traveling fluid bridge
                        Color.clear
                            .modifier(SavedFluidBridgeModifier(
                                progress: isSaved ? 0 : 1,
                                tabWidth: tabWidth,
                                tabHeight: tabHeight,
                                spacing: spacing
                            ))
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                    .tag(1)
                }
                .padding(-30) // Invisible breathing room for blur & spring expansion
                .colorMultiply(Color.textDark)
            }
        }
        .frame(height: tabHeight)
    }
}

private struct SavedFluidBridgeModifier: ViewModifier, Animatable {
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
        let targetCircleSize = tabHeight / 2
        
        let currentHeight = tabHeight - (tabHeight - targetCircleSize) * sinProgress
        let currentWidth = tabWidth - (tabWidth - targetCircleSize) * sinProgress
        
        let startCenterX = tabWidth / 2
        let endCenterX = tabWidth + spacing + tabWidth / 2
        let currentCenterX = startCenterX + progress * (endCenterX - startCenterX)
        
        return Capsule()
            .fill(Color.black)
            .frame(width: currentWidth, height: currentHeight)
            .position(x: currentCenterX, y: tabHeight / 2)
    }
}

#Preview {
    @Previewable @State var tab: SavedTabType = .saved
    ZStack {
        Color.appBackground.ignoresSafeArea()
        SavedGooeyTabView(selectedTab: $tab)
    }
}
