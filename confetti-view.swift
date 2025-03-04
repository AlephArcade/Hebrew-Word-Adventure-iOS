import SwiftUI

/// A simpler confetti animation view
struct ConfettiView: View {
    // Initial setup
    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false
    
    // For cleanup
    @State private var animationTask: DispatchWorkItem?
    
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
        .onDisappear {
            // Proper cleanup when view disappears
            cleanupAnimations()
        }
    }
    
    private func generateConfetti() {
        // Cancel any previous animation task
        cleanupAnimations()
        
        var newParticles: [ConfettiParticle] = []
        
        // Create fewer particles on older devices for better performance
        let particleCount = UIDevice.current.userInterfaceIdiom == .pad ? 100 : 60
        
        for _ in 0..<particleCount {
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
                rotationSpeed: Double.random(in: -720...720)
            )
            
            newParticles.append(particle)
        }
        
        self.particles = newParticles
        self.isAnimating = true
        
        // Create a new animation task
        let task = DispatchWorkItem { [weak self] in
            self?.animateParticles()
        }
        
        self.animationTask = task
        DispatchQueue.main.async(execute: task)
    }
    
    private func animateParticles() {
        // Animate all particles
        for i in 0..<particles.count {
            // Animation delay for a more natural look
            let delay = Double.random(in: 0...0.5)
            let duration = Double.random(in: 1.5...3.0)
            
            // Position animation
            withAnimation(Animation.easeOut(duration: duration).delay(delay)) {
                if i < particles.count {
                    particles[i].position = particles[i].finalPosition
                    particles[i].rotation += particles[i].rotationSpeed
                }
            }
            
            // Fade out animation
            withAnimation(Animation.linear(duration: 0.7).delay(duration * 0.8)) {
                if i < particles.count {
                    particles[i].opacity = 0
                }
            }
        }
        
        // Clean up particles after animation completes
        let cleanupTask = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if self.isAnimating {
                self.particles = []
                self.isAnimating = false
            }
        }
        
        // Store the cleanup task reference
        self.animationTask = cleanupTask
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5, execute: cleanupTask)
    }
    
    private func cleanupAnimations() {
        // Cancel any pending animation tasks
        animationTask?.cancel()
        animationTask = nil
        
        // Clear particles
        particles = []
        isAnimating = false
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
