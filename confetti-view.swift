import SwiftUI

/// An enhanced confetti animation view inspired by iMessage celebrations
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
    private let shapes: [ConfettiShape] = [.circle, .triangle, .square, .star]
    
    var body: some View {
        ZStack {
            // Render each confetti particle
            ForEach(particles) { particle in
                particle.view
                    .position(x: particle.position.x, y: particle.position.y)
                    .rotationEffect(.degrees(particle.rotation))
                    .opacity(particle.opacity)
                    .scaleEffect(particle.scale)
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
        
        // Create particles for a more dramatic effect
        let particleCount = UIDevice.current.userInterfaceIdiom == .pad ? 150 : 100
        
        // Create falling confetti (top to bottom)
        for _ in 0..<particleCount/2 {
            createFallingParticle(particles: &newParticles)
        }
        
        // Create shooting confetti (bottom to top then fall)
        for _ in 0..<particleCount/2 {
            createShootingParticle(particles: &newParticles)
        }
        
        self.particles = newParticles
        self.isAnimating = true
        
        // Create a new animation task
        let task = DispatchWorkItem { [self] in
            animateParticles()
        }
        
        self.animationTask = task
        DispatchQueue.main.async(execute: task)
    }
    
    private func createFallingParticle(particles: inout [ConfettiParticle]) {
        // Randomize properties for each particle
        let shape = shapes.randomElement() ?? .circle
        let color = colors.randomElement() ?? .yellow
        
        // Size varies based on shape
        let size = CGFloat.random(in: 5...20)
        
        // Start position is from top of screen at random x coordinate
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let startX = CGFloat.random(in: 0...screenWidth)
        let startY = CGFloat.random(in: -100...0) // Start above screen
        
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
            scale: 1.0,
            particleType: .falling
        )
        
        particles.append(particle)
    }
    
    private func createShootingParticle(particles: inout [ConfettiParticle]) {
        // Randomize properties for each particle
        let shape = shapes.randomElement() ?? .circle
        let color = colors.randomElement() ?? .yellow
        
        // Size varies based on shape
        let size = CGFloat.random(in: 5...20)
        
        // Start position is from bottom of screen at random x coordinate
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let startX = CGFloat.random(in: 0...screenWidth)
        let startY = screenHeight + CGFloat.random(in: 0...50) // Start below screen
        
        // First shoot up to a peak height
        let peakY = CGFloat.random(in: screenHeight * 0.1...screenHeight * 0.5)
        let peakX = startX + CGFloat.random(in: -screenWidth/3...screenWidth/3)
        
        // Then fall down to somewhere below screen
        let endY = screenHeight + CGFloat.random(in: 0...100)
        let endX = peakX + CGFloat.random(in: -screenWidth/4...screenWidth/4)
        
        // Create the particle
        let particle = ConfettiParticle(
            shape: shape,
            color: color,
            size: size,
            position: CGPoint(x: startX, y: startY),
            finalPosition: CGPoint(x: endX, y: endY),
            intermediatePosition: CGPoint(x: peakX, y: peakY),
            rotation: Double.random(in: 0...360),
            rotationSpeed: Double.random(in: -720...720),
            scale: 1.0,
            particleType: .shooting
        )
        
        particles.append(particle)
    }
    
    private func animateParticles() {
        // Animate all particles
        for i in 0..<particles.count {
            if i >= particles.count { continue } // Safety check
            
            let particle = particles[i]
            let delay = Double.random(in: 0...0.5)
            
            switch particle.particleType {
            case .falling:
                animateFallingParticle(index: i, delay: delay)
            case .shooting:
                animateShootingParticle(index: i, delay: delay)
            }
        }
        
        // Clean up particles after animation completes
        let cleanupTask = DispatchWorkItem { [self] in
            if isAnimating {
                particles = []
                isAnimating = false
            }
        }
        
        // Store the cleanup task reference
        self.animationTask = cleanupTask
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: cleanupTask)
    }
    
    private func animateFallingParticle(index: Int, delay: Double) {
        let duration = Double.random(in: 2.0...4.0)
        
        // Position animation
        withAnimation(Animation.easeOut(duration: duration).delay(delay)) {
            if index < particles.count {
                particles[index].position = particles[index].finalPosition
                particles[index].rotation += particles[index].rotationSpeed
            }
        }
        
        // Scale animation (pulsing effect)
        withAnimation(Animation.easeInOut(duration: 0.5).repeatForever().delay(delay)) {
            if index < particles.count {
                particles[index].scale = CGFloat.random(in: 0.8...1.2)
            }
        }
        
        // Fade out animation
        withAnimation(Animation.linear(duration: 0.7).delay(duration * 0.8)) {
            if index < particles.count {
                particles[index].opacity = 0
            }
        }
    }
    
    private func animateShootingParticle(index: Int, delay: Double) {
        if index >= particles.count { return }
        
        let particle = particles[index]
        guard let intermediatePosition = particle.intermediatePosition else { return }
        
        // First phase: shoot up 
        let riseTime = Double.random(in: 0.5...1.2)
        withAnimation(Animation.easeOut(duration: riseTime).delay(delay)) {
            if index < particles.count {
                particles[index].position = intermediatePosition
                particles[index].rotation += particles[index].rotationSpeed * 0.5
                // Get bigger while rising
                particles[index].scale = 1.5
            }
        }
        
        // Second phase: fall down
        let fallTime = Double.random(in: 1.5...3.0)
        withAnimation(Animation.easeIn(duration: fallTime).delay(delay + riseTime)) {
            if index < particles.count {
                particles[index].position = particle.finalPosition
                particles[index].rotation += particles[index].rotationSpeed
            }
        }
        
        // Scale animation during fall (pulsing effect)
        withAnimation(Animation.easeInOut(duration: 0.3).repeatForever().delay(delay + riseTime)) {
            if index < particles.count {
                particles[index].scale = CGFloat.random(in: 0.7...1.3)
            }
        }
        
        // Fade out animation
        withAnimation(Animation.linear(duration: 0.7).delay(delay + riseTime + fallTime * 0.7)) {
            if index < particles.count {
                particles[index].opacity = 0
            }
        }
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

/// Individual confetti particle with enhanced structure
struct ConfettiParticle: Identifiable {
    let id = UUID()
    let shape: ConfettiShape
    let color: Color
    let size: CGFloat
    
    var position: CGPoint
    let finalPosition: CGPoint
    let intermediatePosition: CGPoint?
    var rotation: Double
    let rotationSpeed: Double
    var opacity: Double = 1.0
    var scale: CGFloat = 1.0
    let particleType: ParticleType
    
    init(shape: ConfettiShape, color: Color, size: CGFloat, position: CGPoint, finalPosition: CGPoint, 
         intermediatePosition: CGPoint? = nil, rotation: Double, rotationSpeed: Double, 
         scale: CGFloat = 1.0, particleType: ParticleType) {
        self.shape = shape
        self.color = color
        self.size = size
        self.position = position
        self.finalPosition = finalPosition
        self.intermediatePosition = intermediatePosition
        self.rotation = rotation
        self.rotationSpeed = rotationSpeed
        self.scale = scale
        self.particleType = particleType
    }
    
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
            case .star:
                Star(points: 5, innerRatio: 0.5)
                    .fill(color)
                    .frame(width: size, height: size)
            }
        }
    }
}

enum ParticleType {
    case falling
    case shooting
}

/// Available confetti shapes (extended)
enum ConfettiShape {
    case circle
    case triangle
    case square
    case star
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

/// Custom star shape
struct Star: Shape {
    let points: Int
    let innerRatio: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * innerRatio
        
        var path = Path()
        let angleIncrement = .pi * 2 / CGFloat(points * 2)
        
        for i in 0..<(points * 2) {
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = CGFloat(i) * angleIncrement - .pi / 2
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}
