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
                            Color.secondaryBackground
                                .rippleEffect(color: Color.textSecondary.opacity(0.2))
                        )
                        .clipShape(Capsule())
                }
                
                Button(action: onNext) {
                    Text("Next")
                        .font(.custom("InclusiveSans-Regular", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            Color.textSecondary
                                .rippleEffect(color: Color.white.opacity(0.3))
                        )
                        .clipShape(Capsule())
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 34) // Account for home indicator
        .background(Color.appBackground)
    }
}
