import SwiftUI

struct PublicationCard: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Placeholder for Logo
                Circle()
                    .fill(Color.appBackground) 
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "newspaper.fill")
                            .foregroundColor(.textSecondary)
                            .font(.system(size: 24))
                    )
                
                Text(title)
                    .font(.custom("InclusiveSans-Regular", size: 16))
                    .foregroundColor(isSelected ? .linkGreen : .textDark)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(16)
            .background(Color.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: isSelected ? 40 : 32))
            .overlay(
                RoundedRectangle(cornerRadius: isSelected ? 40 : 32)
                    .stroke(isSelected ? Color.linkGreen : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(RippleButtonStyle(rippleColor: Color.brandGreen.opacity(0.3)))
        .animation(.easeOut(duration: 0.25), value: isSelected)
        .frame(height: 169)
    }
}
