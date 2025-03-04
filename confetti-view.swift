import SwiftUI

struct ConfettiView: View {
    @State private var confetti: [ConfettiPiece] = []
    @State private var isActive = false
    
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    let shapes: [ConfettiShape] = [.circle, .triangle, .square]
    
    var body: some View {
        ZStack {
            ForEach(confetti) { piece in
                piece.view
                    .position(
                        x: piece.position.x,
                        y: piece.position.y
                    )
                    .opacity(piece.opacity)
                    .rotationEffect(.degrees(piece.rotation))
            }
        }
        .onAppear {
            if !isActive {
                isActive = true
                createConfetti()
            }
        }
    }
    
    func createConfetti() {
        for _ in 0..<60 {
            let shape = shapes.randomElement()!
            let color = colors.randomElement()!
            let size = CGFloat.random(in: 5...15)
            
            let piece = ConfettiPiece(
                shape: shape,
                color: color,
                size: size,
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: -size
                ),
                finalPosition: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: UIScreen.main.bounds.height + size
                ),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -720...720),
                fallSpeed: Double.random(in: 1.0...3.0)
            )
            
            confetti.append(piece)
            
            // Animate each piece
            withAnimation(Animation.linear(duration: Double.random(in: 1.0...3.0))
                            .delay(Double.random(in: 0...1.0))) {
                confetti[confetti.count - 1].position = piece.finalPosition
                confetti[confetti.count - 1].rotation += piece.rotationSpeed
                
                // Fade out near the end
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.8...2.8)) {
                    if confetti.indices.contains(confetti.count - 1) {
                        withAnimation(.linear(duration: 0.2)) {
                            confetti[confetti.count - 1].opacity = 0
                        }
                    }
                }
            }
        }
        
        // Remove confetti after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            confetti.removeAll()
            isActive = false
        }
    }
}

// Confetti piece model
struct ConfettiPiece: Identifiable {
    let id = UUID()
    let shape: ConfettiShape
    let color: Color
    let size: CGFloat
    
    var position: CGPoint
    let finalPosition: CGPoint
    var rotation: Double
    let rotationSpeed: Double
    let fallSpeed: Double
    var opacity: Double = 1.0
    
    var view: some View {
        Group {
            switch shape {
            case .circle:
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
            case .triangle:
                Triangle()
                    .fill(color)
                    .frame(width: size, height: size)
            case .square:
                Rectangle()
                    .fill(color)
                    .frame(width: size, height: size)
            }
        }
    }
}

enum ConfettiShape {
    case circle
    case triangle
    case square
}

// Custom triangle shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// ConfettiModifier to easily add confetti to any view
struct ConfettiModifier: ViewModifier {
    @Binding var isActive: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isActive {
                ConfettiView()
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .onAppear {
                        // Automatically deactivate confetti after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                            isActive = false
                        }
                    }
            }
        }
    }
}

// Extension to make the modifier easier to use
extension View {
    func confetti(isActive: Binding<Bool>) -> some View {
        self.modifier(ConfettiModifier(isActive: isActive))
    }
}
