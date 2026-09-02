import SwiftUI

struct TestView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 28)
            .glassEffect(.regular.tint(.white.opacity(0.8)), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}
