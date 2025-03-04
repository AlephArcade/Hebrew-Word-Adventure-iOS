import SwiftUI

/// A modern confetti view inspired by SimonBachmann's ConfettiSwiftUI
struct ImprovedConfettiView: View {
    // Configuration
    private let particleCount: Int
    private let colors: [Color]
    private let shapes: [ConfettiShape]
    private let confettiSize: CGFloat
    private let rainHeight: CGFloat
    private let opacity: Double
    private let openingAngle: Angle
    private let closingAngle: Angle
    private let radius: CGFloat
    
    // Animation state
    @State private var isAnimating = false
    
    init(
        particleCount: Int = 40,
        colors: [Color] = [.blue, .red, .green, .yellow, .pink, .purple, .orange],
        shapes: [ConfettiShape] = [.circle, .triangle, .square, .slimRectangle, .roundedCross],
        confettiSize: CGFloat = 10.0,
        rainHeight: CGFloat = 600.0,
        opacity: Double = 1.0,
        openingAngle: Angle = .degrees(60),
        closingAngle: Angle = .degrees(120),
        radius: CGFloat = 300
    ) {
        self.particleCount = particleCount
        self.colors = colors
        self.shapes = shapes
        self.confettiSize = confettiSize
        self.rainHeight = rainHeight
        self.opacity = opacity
        self.openingAngle = openingAngle
        self.closingAngle = closingAngle
        self.radius = radius
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                ConfettiParticleView(
                    shape: shapes[index % shapes.count],
                    color: colors[index % colors.count],
                    size: confettiSize,
                    openingAngle: openingAngle,
                    closingAngle: closingAngle,
                    radius: radius,
                    rainHeight: rainHeight,
                    opacity: opacity,
                    isAnimating: isAnimating
                )
            }
        }
        .onAppear {
            // Start the animation as soon as the view appears
            DispatchQueue.main.async {
                isAnimating = true
            }
        }
    }
}

/// Individual confetti particle
struct ConfettiParticleView: View {
    let shape: ConfettiShape
    let color: Color
    let size: CGFloat
    let openingAngle: Angle
    let closingAngle: Angle
    let radius: CGFloat
    let rainHeight: CGFloat
    let opacity: Double
    let isAnimating: Bool
    
    // Animation state
    @State private var location = CGPoint.zero
    @State private var particleOpacity = 0.0
    @State private var rotation3DX = 0.0
    @State private var rotation3DZ = 0.0
    
    // Randomized values for varied animation
    private let spinDirectionX: Double
    private let spinDirectionZ: Double
    private let rotationSpeed: Double
    private let rotationSpeedZ: Double
    private let randomAnchor: CGFloat
    
    // Task for proper cancellation
    @State private var rainAnimationTask: DispatchWorkItem?
    
    init(
        shape: ConfettiShape,
        color: Color,
        size: CGFloat,
        openingAngle: Angle,
        closingAngle: Angle,
        radius: CGFloat,
        rainHeight: CGFloat,
        opacity: Double,
        isAnimating: Bool
    ) {
        self.shape = shape
        self.color = color
        self.size = size
        self.openingAngle = openingAngle
        self.closingAngle = closingAngle
        self.radius = radius
        self.rainHeight = rainHeight
        self.opacity = opacity
        self.isAnimating = isAnimating
        
        // Initialize random values during init to avoid @State vars that never change
        self.spinDirectionX = Double.random(in: -1...1) > 0 ? 1.0 : -1.0
        self.spinDirectionZ = Double.random(in: -1...1) > 0 ? 1.0 : -1.0
        self.rotationSpeed = Double.random(in: 1.0...3.0)
        self.rotationSpeedZ = Double.random(in: 1.0...3.0)
        self.randomAnchor = CGFloat.random(in: 0...1).rounded()
    }
    
    var body: some View {
        confettiShapeView
            .frame(width: size, height: size)
            .foregroundColor(color)
            .opacity(particleOpacity)
            .position(location)
            .rotation3DEffect(.degrees(rotation3DX), axis: (x: spinDirectionX, y: 0, z: 0))
            .rotation3DEffect(.degrees(rotation3DZ), axis: (x: 0, y: 0, z: spinDirectionZ), anchor: UnitPoint(x: randomAnchor, y: randomAnchor))
            .onChange(of: isAnimating) { startAnimation in
                if startAnimation {
                    // Trigger the animation sequence
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        particleOpacity = opacity
                        
                        // Calculate random angle for explosion direction
                        let minAngle = CGFloat(openingAngle.degrees)
                        let maxAngle = CGFloat(closingAngle.degrees)
                        let randomAngle: CGFloat
                        
                        if minAngle <= maxAngle {
                            randomAngle = CGFloat.random(in: minAngle...maxAngle)
                        } else {
                            // Handle wrap-around case (e.g., 330° to 30°)
                            randomAngle = CGFloat.random(in: minAngle...(maxAngle + 360)).truncatingRemainder(dividingBy: 360)
                        }
                        
                        // Calculate random distance for explosion radius
                        let distance = pow(CGFloat.random(in: 0.01...1), 2.0/7.0) * radius
                        
                        // Calculate position using angle and distance
                        location.x = distance * cos(deg2rad(randomAngle))
                        location.y = -distance * sin(deg2rad(randomAngle))
                        
                        // Start 3D rotation immediately
                        rotation3DX = 360 * rotationSpeed
                        rotation3DZ = 360 * rotationSpeedZ
                    }
                    
                    // Cancel any existing delayed tasks
                    rainAnimationTask?.cancel()
                    
                    // Create a new task for rain animation
                    let task = DispatchWorkItem { [self] in
                        withAnimation(.timingCurve(0.12, 0, 0.39, 0, duration: Double(rainHeight / 300))) {
                            location.y += rainHeight
                            particleOpacity = 0
                        }
                    }
                    rainAnimationTask = task
                    
                    // Schedule the rain animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: task)
                }
            }
            .onDisappear {
                // Clean up any pending tasks
                rainAnimationTask?.cancel()
                rainAnimationTask = nil
            }
    }
    
    private func deg2rad(_ number: CGFloat) -> CGFloat {
        return number * CGFloat.pi / 180
    }
    
    @ViewBuilder
    private var confettiShapeView: some View {
        switch shape {
        case .circle:
            Circle()
        case .triangle:
            Triangle()
        case .square:
            Rectangle()
        case .slimRectangle:
            Rectangle()
                .frame(width: size, height: size / 3)
        case .roundedCross:
            RoundedCross()
        }
    }
}

// MARK: - Shape Definitions

enum ConfettiShape {
    case circle
    case triangle
    case square
    case slimRectangle
    case roundedCross
}

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

struct RoundedCross: Shape {
    func path(in rect: CGRect) -> Path {
        let width = min(rect.width, rect.height)
        let halfWidth = width / 2
        let quarterWidth = width / 4
        
        var path = Path()
        
        // Vertical bar
        path.addRoundedRect(
            in: CGRect(
                x: halfWidth - quarterWidth,
                y: 0,
                width: halfWidth,
                height: width
            ),
            cornerSize: CGSize(width: quarterWidth, height: quarterWidth)
        )
        
        // Horizontal bar
        path.addRoundedRect(
            in: CGRect(
                x: 0,
                y: halfWidth - quarterWidth,
                width: width,
                height: halfWidth
            ),
            cornerSize: CGSize(width: quarterWidth, height: quarterWidth)
        )
        
        return path
    }
}
