import SwiftUI

struct FallingConfettiView: View {
    let count: Int
    let colors: [Color]
    
    init(count: Int = 50, colors: [Color] = [.red, .blue, .green, .yellow, .pink, .purple, .orange]) {
        self.count = count
        self.colors = colors
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                ConfettiPiece(color: colors[index % colors.count])
            }
        }
    }
}

struct ConfettiPiece: View {
    let color: Color
    
    // Random initial values for animation
    @State private var xPosition: CGFloat
    @State private var yPosition: CGFloat = -50
    @State private var rotation: Double
    @State private var scale: CGFloat
    @State private var animationDelay: Double
    
    init(color: Color) {
        self.color = color
        
        // Initialize random values
        self._xPosition = State(initialValue: CGFloat.random(in: 0...UIScreen.main.bounds.width))
        self._rotation = State(initialValue: Double.random(in: 0...360))
        self._scale = State(initialValue: CGFloat.random(in: 0.7...1.3))
        self._animationDelay = State(initialValue: Double.random(in: 0...0.5))
    }
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 10, height: 10)
            .scaleEffect(scale)
            .rotationEffect(Angle(degrees: rotation))
            .position(x: xPosition, y: yPosition)
            .onAppear {
                // Delay the animation start for more natural effect
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) {
                    // Animate falling down
                    withAnimation(Animation.linear(duration: 3)) {
                        yPosition = UIScreen.main.bounds.height + 100
                        rotation += Double.random(in: 180...360)
                        xPosition += CGFloat.random(in: -50...50)
                    }
                }
            }
    }
}
