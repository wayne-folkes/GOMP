//
//  TicTacToeView.swift
//  TicTacToe
//
//  Created by Wayne Folkes on 1/27/26.
//

import SwiftUI

struct TicTacToeView: View {
    @StateObject private var gameState = TicTacToeGameState()
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            // Dynamic Background
            LinearGradient(gradient: Gradient(colors: gameState.currentPlayer == .x ? [Color.blue, Color.cyan] : [Color.pink, Color.orange]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
                .animation(.easeInOut(duration: 0.5), value: gameState.currentPlayer)
            
            VStack(spacing: 20) {
                Text("Tic Tac Toe")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                
                Text(statusText)
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                    ForEach(0..<9) { index in
                        CellView(player: gameState.board[index])
                            .onTapGesture {
                                gameState.makeMove(at: index)
                            }
                    }
                }
                .padding()
                
                Button(action: {
                    showConfetti = false
                    gameState.resetGame()
                }) {
                    Text("Restart Game")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .foregroundColor(gameState.currentPlayer == .x ? .blue : .pink)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .padding(.horizontal)
                .opacity(gameState.winner != nil || gameState.isDraw ? 1.0 : 0.0)
            }
            .padding()
            .onChange(of: gameState.winner) { _, newValue in
                if newValue != nil {
                    withAnimation(.easeIn(duration: 0.3)) {
                        showConfetti = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showConfetti = false
                        }
                    }
                }
            }
            .onChange(of: gameState.isDraw) { _, newValue in
                if newValue {
                    withAnimation(.easeIn(duration: 0.3)) {
                        showConfetti = false
                    }
                }
            }
            
            // Confetti overlay
            if showConfetti {
                ConfettiView()
                    .transition(.opacity)
                    .ignoresSafeArea()
            }
        }
    }
    
    var statusText: String {
        if let winner = gameState.winner {
            return "\(winner.rawValue) Wins!"
        } else if gameState.isDraw {
            return "It's a Draw!"
        } else {
            return "Player \(gameState.currentPlayer.rawValue)'s Turn"
        }
    }
}

struct CellView: View {
    let player: Player?
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.6))
                .aspectRatio(1.0, contentMode: .fit)
                .shadow(radius: 2)
            
            if let player = player {
                Text(player.rawValue)
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(player == .x ? .blue : .pink)
                    .shadow(color: .white, radius: 1)
            }
        }
    }
}

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
                // Visibility is controlled by the parent (ContentView)
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
