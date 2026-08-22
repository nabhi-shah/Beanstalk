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
            isSelected ? .regular.tint(Color.brandGreen.opacity(0.4)).interactive() : .regular.interactive(),
            in: .rect(cornerRadius: isSelected ? 40 : 32)
        )
        .overlay(
            RoundedRectangle(cornerRadius: isSelected ? 40 : 32)
                .stroke(
                    LinearGradient(
                        colors: isSelected ? [Color.brandGreen.opacity(0.8), Color.brandGreen.opacity(0.2)] : [Color.black.opacity(0.1), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .shadow(color: isSelected ? Color.brandGreen.opacity(0.15) : Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .rippleEffect(color: Color.brandGreen.opacity(0.3)) { _ in
            action()
        }
        .animation(.easeOut(duration: 0.25), value: isSelected)
        .frame(height: 169)
    }
}
