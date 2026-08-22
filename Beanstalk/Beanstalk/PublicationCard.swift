import SwiftUI

struct PublicationCard: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
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
        .glassEffect(
            isSelected ? .regular.tint(Color.brandGreen.opacity(0.2)) : .regular,
            in: .rect(cornerRadius: isSelected ? 40 : 32)
        )
        .rippleEffect(color: Color.brandGreen.opacity(0.3)) { _ in
            action()
        }
        .animation(.easeOut(duration: 0.25), value: isSelected)
        .frame(height: 169)
    }
}
