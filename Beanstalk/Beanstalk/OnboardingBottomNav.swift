import SwiftUI

struct OnboardingBottomNav: View {
    let onBack: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Page Indicator
            HStack(spacing: 6) {
                Circle().fill(Color.brandGreen).frame(width: 7, height: 7)
                Circle().fill(Color.brandGreen).frame(width: 7, height: 7)
                Capsule().fill(Color.textSecondary).frame(width: 27, height: 7)
                Circle().fill(Color.secondaryBackground).frame(width: 7, height: 7)
                Circle().fill(Color.secondaryBackground).frame(width: 7, height: 7)
            }
            .padding(.top, 8)
            
            // Buttons
            HStack(spacing: 8) {
                Button(action: onBack) {
                    Text("Back")
                        .font(.custom("InclusiveSans-Regular", size: 16))
                        .foregroundColor(.textDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            ZStack {
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .environment(\.colorScheme, .light)
                                Capsule()
                                    .fill(Color.secondaryBackground.opacity(0.6))
                            }
                        )
                        .overlay(
                            Capsule().stroke(
                                LinearGradient(colors: [Color.white.opacity(0.8), Color.white.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1
                            )
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.plain)
                
                Button(action: onNext) {
                    Text("Next")
                        .font(.custom("InclusiveSans-Regular", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            ZStack {
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .environment(\.colorScheme, .light)
                                Capsule()
                                    .fill(
                                        LinearGradient(colors: [Color.textSecondary.opacity(0.8), Color.textSecondary.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                            }
                        )
                        .overlay(
                            Capsule().stroke(
                                LinearGradient(colors: [Color.white.opacity(0.8), Color.white.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1
                            )
                        )
                        .shadow(color: Color.textSecondary.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 34) // Account for home indicator
    }
}
