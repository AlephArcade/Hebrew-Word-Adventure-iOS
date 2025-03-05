import SwiftUI

/// A simplified confetti view that properly animates confetti particles
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
                    opacity: opacity
                )
            }
        }
    }
}

struct ConfettiParticleView: View {
    let shape: ConfettiShape
    let color: Color
    let size: CGFloat
    let openingAngle: Angle
    let closingAngle: Angle
    let radius: CGFloat
    let rainHeight: CGFloat
    let opacity: Double
    
    // Animation state
    @State private var xPosition: CGFloat = 0
    @State private var yPosition: CGFloat = 0
    @State private var particleOpacity: Double = 0.0
    @State private var rotation: Double = 0.0
    @State private var rotation3D: Double = 0.0
    
    // Randomized values for varied animation
    private let randomX: CGFloat
    private let randomY: CGFloat
    private let randomDelay: Double
    private let randomRotationSpeed: Double
    private let spinDirection: Double
    
    init(
        shape: ConfettiShape,
        color: Color,
        size: CGFloat,
        openingAngle: Angle,
        closingAngle: Angle,
        radius: CGFloat,
        rainHeight: CGFloat,
        opacity: Double
    ) {
        self.shape = shape
        self.color = color
        self.size = size
        self.openingAngle = openingAngle
        self.closingAngle = closingAngle
        self.radius = radius
        self.rainHeight = rainHeight
        self.opacity = opacity
        
        // Initialize with random values for natural variation
        self.randomX = CGFloat.random(in: -radius...radius)
        self.randomY = CGFloat.random(in: -20...20)
        self.randomDelay = Double.random(in: 0...0.3)
        self.randomRotationSpeed = Double.random(in: 0.5...2.0)
        self.spinDirection = Double.random(in: -1...1) > 0 ? 1.0 : -1.0
    }
    
    var body: some View {
        confettiShapeView
            .frame(width: size, height: size)
            .foregroundColor(color)
            .opacity(particleOpacity)
            .position(x: xPosition, y: yPosition)
            .rotationEffect(.degrees(rotation))
            .rotation3DEffect(.degrees(rotation3D), axis: (x: 0, y: spinDirection, z: 0))
            .onAppear {
                startAnimation()
            }
    }
    
    private func startAnimation() {
        // Position the confetti at the starting point with zero opacity
        xPosition = randomX
        yPosition = randomY - size
        particleOpacity = 0
        
        // Delayed start for a more natural look
        DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay) {
            // First animation phase: Explosion/spread and fade in
            withAnimation(.easeOut(duration: 0.3)) {
                particleOpacity = opacity
                
                // Calculate random angle for explosion direction
                let minAngle = CGFloat(openingAngle.degrees)
                let maxAngle = CGFloat(closingAngle.degrees)
                let randomAngle = CGFloat.random(in: minAngle...maxAngle)
                
                // Calculate position using angle and distance
                let distance = pow(CGFloat.random(in: 0.1...1), 0.5) * radius
                xPosition = distance * cos(deg2rad(randomAngle))
                yPosition = -distance * sin(deg2rad(randomAngle))
            }
            
            // Apply continuous rotation for spinning effect
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360 * randomRotationSpeed
                rotation3D = 360 * randomRotationSpeed
            }
            
            // Second animation phase: Falling down
            withAnimation(.easeIn(duration: Double(rainHeight / 200)).delay(0.3)) {
                yPosition += rainHeight
                particleOpacity = 0
            }
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

// IMPORTANT: DO NOT include the View extension here, it's already in ContentView.swift
