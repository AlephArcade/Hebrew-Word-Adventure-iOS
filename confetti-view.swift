import SwiftUI

/// A simplified confetti animation view that creates a celebration effect
struct ConfettiView: View {
    // Initial setup
    @State private var particles: [ConfettiParticle] = []
    
    // Color palette similar to HTML version
    private let colors: [Color] = [
        Color(red: 1.0, green: 0.85, blue: 0.35), // FFEB3B yellowish
        Color(red: 0.3, green: 0.69, blue: 0.31), // 4CAF50 greenish
        Color(red: 0.13, green: 0.59, blue: 0.95), // 2196F3 blueish
        Color(red: 0.91, green: 0.12, blue: 0.39), // E91E63 pinkish
        Color(red: 0.61, green: 0.15, blue: 0.69)  // 9C27B0 purplish
    ]
    
    // Different confetti shapes
    private let shapes: [ConfettiShape] = [.circle, .triangle, .square]
    
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
            // Generate confetti when view appears
            generateConfetti()
        }
    }
    
    private func generateConfetti() {
        // Create an array to hold particle data 
        var newParticles: [ConfettiParticle] = []
        
        for _ in 0..<100 {
            // Randomize properties for each particle
            let shape = shapes.randomElement() ?? .circle
            let color = colors.randomElement() ?? .yellow
            
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
                fallSpeed: Double.random(in: 1.0...2.5)
            )
            
            newParticles.append(particle)
        }
        
        // Add all the particles
        self.particles = newParticles
        
        // Animate each particle
        for i in 0..<particles.count {
            // Animation delay for a more natural look
            let delay = Double.random(in: 0...0.5)
            let duration = Double.random(in: 1.5...3.0)
            
            // Update position with animation
            withAnimation(Animation.easeOut(duration: duration).delay(delay)) {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.1) {
                    if i < self.particles.count {
                        self.particles[i].position = self.particles[i].finalPosition
                        self.particles[i].rotation += self.particles[i].rotationSpeed
                    }
                }
            }
            
            // Fade out animation
            withAnimation(Animation.linear(duration: 0.7).delay(duration * 0.8)) {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.8) {
                    if i < self.particles.count {
                        self.particles[i].opacity = 0
                    }
                }
            }
        }
        
        // Remove particles after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            self.particles = []
        }
    }
}

/// Individual confetti particle with simplified structure
struct ConfettiParticle: Identifiable {
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

/// Available confetti shapes (simplified)
enum ConfettiShape {
    case circle
    case triangle
    case square
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
