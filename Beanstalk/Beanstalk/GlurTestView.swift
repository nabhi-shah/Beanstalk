import SwiftUI
import Glur

struct GlurTestView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 50) {
                    Text("Glur on Colored Objects & Images")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding(.top, 40)
                    
                    // Example 1: A colored rectangle with default glur
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 200, height: 200)
                        .glur() // Default progressive blur (downward)
                    
                    // Example 2: A colored circle with customized glur
                    Circle()
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 200, height: 200)
                        .glur(radius: 20, offset: 0.3, interpolation: 0.5, direction: .up)
                        
                    // Example 3: An image with progressive bleed glur
                    Image("NY Times")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 200)
                        .background(Color.white)
                        .clipped()
                        .progressiveBleedBlur(radius: 94, offset: 0.84, direction: .bottom, steps: 16)
                }
                .padding(.bottom, 100)
            }
        }
    }
}

#Preview {
    GlurTestView()
}
