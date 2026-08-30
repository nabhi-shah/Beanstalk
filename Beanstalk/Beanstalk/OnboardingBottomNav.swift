import SwiftUI

struct OnboardingBottomNav: View {
    var isNextEnabled: Bool
    let onBack: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: onBack) {
                Text("Back")
                    .font(.custom("InclusiveSans-Regular", size: 16))
                    .foregroundColor(.textDark)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.white.opacity(0.01))
                    .clipShape(Capsule())
            }
            .buttonStyle(RippleButtonStyle(rippleColor: Color.textSecondary.opacity(0.2)))
            .background(
                Capsule()
                    .glassEffect(.regular.tint(Color.secondaryBackground.opacity(0)), in: .capsule)
            )
            
            Button(action: onNext) {
                Text("Next")
                    .font(.custom("InclusiveSans-Regular", size: 16))
                    .foregroundColor(isNextEnabled ? .white : .textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.white.opacity(0.01))
                    .clipShape(Capsule())
            }
            .disabled(!isNextEnabled)
            .buttonStyle(RippleButtonStyle(rippleColor: Color.white.opacity(0.3)))
            .background(
                Capsule()
                    .glassEffect(.regular.tint(isNextEnabled ? Color.brandGreen.opacity(0.9) : Color.textSecondary.opacity(0.2)), in: .capsule)
            )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 34) // Account for home indicator
    }
}
