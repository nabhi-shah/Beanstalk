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
                        .background(Color.white.opacity(0.01))
                        .clipShape(Capsule())
                }
                .buttonStyle(RippleButtonStyle(rippleColor: Color.textSecondary.opacity(0.3)))
                .background(
                    Capsule()
                        .glassEffect(.regular.tint(Color.secondaryBackground.opacity(0.5)), in: .capsule)
                )
                
                Button(action: onNext) {
                    Text("Next")
                        .font(.custom("InclusiveSans-Regular", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white.opacity(0.01))
                        .clipShape(Capsule())
                }
                .buttonStyle(RippleButtonStyle(rippleColor: Color.white.opacity(0.3)))
                .background(
                    Capsule()
                        .glassEffect(.regular.tint(Color.textSecondary.opacity(0.6)), in: .capsule)
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 34) // Account for home indicator
    }
}
