import SwiftUI

/// An enhanced confetti animation view that creates a celebration effect
struct ConfettiView: View {
    // Configuration
    private let particleCount = 100
    private let duration: Double = 3.0
    private let opacityDelay: Double = 2.5
    
    // Color palette similar to HTML version
    private let colors: [Color] = [
        Color(red: 1.0, green: 0.85, blue: 0.35), // FFEB3B yellowish
        Color(red: 0.3, green: 0.69, blue: 0.31), // 4CAF50 greenish
        Color(red: 0.13, green: 0.59, blue: 0.95), // 2196F3 blueish
        Color(red: 0.91, green: 0.12, blue: 0.39), // E91E63 pinkish
        Color(red: 0.61, green: 0.15, blue: 0.69)  // 9C27B0 purplish
    ]
    
    // Different confetti shapes
    private let shapes: [ConfettiShape] = [.circle, .triangle, .square, .slimRectangle, .hexagon]
    
    // Track created particles
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        ZStack {
            // Render each confetti particle
            ForEach(particles) { particle in
                particle.view
                    .position(x: particle.position.x, y: particle.position.y)
                    .rotationEffect(.degrees(particle.rotation))
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            generateConfetti()
        }
    }
    
    /// Create confetti particles with random properties
    private func generateConfetti() {
        particles = (0..<particleCount).map { _ in
            // Randomize properties for each particle
            let shape = shapes.randomElement()!
            let color = colors.randomElement()!
            
            // Size varies based on shape
            let size = CGFloat.random(in: 5...15)
            
            // Start position is from top of screen at random x coordinate
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            let startX = CGFloat.random(in: 0...screenWidth)
            let startY = CGFloat.random(in: -50...10) // Start slightly above screen
            
            // End position is somewhere toward bottom of screen
            let endX = startX + CGFloat.random(in: -screenWidth/2...screenWidth/2)
            let endY = screenHeight + CGFloat.random(in: 0...100)
            
            // Create the particle
            let particle = ConfettiParticle(
                shape: shape,
                color: color,
                size: size,
                position: CGPoint(x: startX, y: startY),
                finalPosition: CGPoint(x: endX, y: endY),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -720...720),
                swingRange: Double.random(in: 0...30),
                swingSpeed: Double.random(in: 1...3),
                fallSpeed: Double.random(in: 1.0...2.5)
            )
            
            // Animate particle falling
            withAnimation(
                Animation
                    .easeOut(duration: duration * particle.fallSpeed)
                    .delay(Double.random(in: 0...0.5))
            ) {
                // Update position in particles array
                let index = particles.count
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if index < particles.count {
                        particles[index].position = particle.finalPosition
                        particles[index].rotation += particle.rotationSpeed
                    }
                }
            }
            
            // Fade out toward the end
            withAnimation(
                Animation
                    .linear(duration: 0.7)
                    .delay(opacityDelay * particle.fallSpeed)
            ) {
                let index = particles.count
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if index < particles.count {
                        particles[index].opacity = 0
                    }
                }
            }
            
            return particle
        }
    }
}

/// Individual confetti particle
struct ConfettiParticle: Identifiable {
    let id = UUID()
    let shape: ConfettiShape
    let color: Color
    let size: CGFloat
    
    var position: CGPoint
    let finalPosition: CGPoint
    var rotation: Double
    let rotationSpeed: Double
    let swingRange: Double
    let swingSpeed: Double
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
            case .slimRectangle:
                Rectangle()
                    .fill(color)
                    .frame(width: size/3, height: size)
            case .hexagon:
                Hexagon()
                    .fill(color)
                    .frame(width: size, height: size)
            }
        }
    }
}

/// Available confetti shapes
enum ConfettiShape {
    case circle
    case triangle
    case square
    case slimRectangle
    case hexagon
}

/// Custom triangle shape
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

/// Custom hexagon shape
struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        // Six points of the hexagon
        let points = (0..<6).map { i -> CGPoint in
            let angle = Double(i) * .pi / 3
            return CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
        }
        
        path.move(to: points[0])
        for i in 1..<6 {
            path.addLine(to: points[i])
        }
        path.closeSubpath()
        
        return path
    }
}

/// Modifier to add confetti to any view
struct ConfettiModifier: ViewModifier {
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                ConfettiView()
                    .allowsHitTesting(false)  // Let touches pass through
                    .transition(.opacity)
                    .onAppear {
                        // Auto-dismiss after animation completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                            isPresented = false 
                        }
                    }
            }
        }
    }
}

/// Extension to make applying confetti easier
extension View {
    func confetti(isPresented: Binding<Bool>) -> some View {
        self.modifier(ConfettiModifier(isPresented: isPresented))
    }
}
