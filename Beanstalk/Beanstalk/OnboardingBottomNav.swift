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
                Text("Back")
                    .font(.custom("InclusiveSans-Regular", size: 16))
                    .foregroundColor(.textDark)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        ZStack {
                            Capsule().fill(.ultraThinMaterial)
                            Capsule().fill(Color.white.opacity(0.3))
                        }
                        .rippleEffect(color: Color.textSecondary.opacity(0.2)) { _ in
                            onBack()
                        }
                    )
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1)
                    )
                
                Text("Next")
                    .font(.custom("InclusiveSans-Regular", size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        ZStack {
                            Capsule().fill(.ultraThinMaterial)
                            Capsule().fill(Color.textSecondary.opacity(0.4))
                        }
                        .rippleEffect(color: Color.white.opacity(0.3)) { _ in
                            onNext()
                        }
                    )
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 34) // Account for home indicator
    }
}
