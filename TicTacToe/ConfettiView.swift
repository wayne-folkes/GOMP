import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = (0..<120).map { _ in ConfettiParticle.random() }
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles.indices, id: \.self) { i in
                    ConfettiPiece(particle: particles[i], containerSize: geo.size, animate: animate)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.05)) {
                    animate = true
                }
            }
        }
    }
}

private struct ConfettiPiece: View {
    let particle: ConfettiParticle
    let containerSize: CGSize
    let animate: Bool

    var body: some View {
        let startX = particle.startX * containerSize.width
        let endX = startX + particle.drift * containerSize.width
        let startY: CGFloat = -20
        let endY = containerSize.height + 40
        let rotation = Angle.degrees(animate ? particle.rotationEnd : particle.rotationStart)

        RoundedRectangle(cornerRadius: particle.shapeCorner)
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size * particle.aspect)
            .position(x: animate ? endX : startX, y: animate ? endY : startY)
            .rotationEffect(rotation)
            .opacity(0.9)
            .blendMode(.plusLighter)
            .animation(
                .interpolatingSpring(stiffness: 40, damping: 10)
                .speed(particle.speed)
                .delay(particle.delay), value: animate
            )
    }
}

private struct ConfettiParticle {
    let color: Color
    let size: CGFloat
    let aspect: CGFloat
    let startX: CGFloat // 0..1
    let drift: CGFloat  // -0.5..0.5
    let rotationStart: Double
    let rotationEnd: Double
    let shapeCorner: CGFloat
    let speed: Double
    let delay: Double

    static func random() -> ConfettiParticle {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .cyan]
        let color = colors.randomElement() ?? .white
        let size = CGFloat.random(in: 6...14)
        let aspect = CGFloat.random(in: 0.6...1.6)
        let startX = CGFloat.random(in: 0...1)
        let drift = CGFloat.random(in: -0.35...0.35)
        let rotationStart = Double.random(in: -90...90)
        let rotationEnd = rotationStart + Double.random(in: 360...900)
        let shapeCorner = CGFloat.random(in: 1...4)
        let speed = Double.random(in: 0.6...1.4)
        let delay = Double.random(in: 0...0.3)
        return ConfettiParticle(color: color, size: size, aspect: aspect, startX: startX, drift: drift, rotationStart: rotationStart, rotationEnd: rotationEnd, shapeCorner: shapeCorner, speed: speed, delay: delay)
    }
}
