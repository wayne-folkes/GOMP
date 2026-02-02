//
//  TwentyFortyEightView.swift
//  GOMP
//
//  Created on 2/1/26.
//

import SwiftUI

struct TwentyFortyEightView: View {
    @StateObject private var gameState = TwentyFortyEightGameState()
    @State private var showWinAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            GameHeaderView(
                title: "2048",
                score: gameState.score,
                scoreColor: .primary
            )
            .padding(.top, 16)
            
            // Theme Picker
            HStack {
                Text("Theme:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Theme", selection: Binding(
                    get: { gameState.colorScheme },
                    set: { newScheme in
                        gameState.colorScheme = newScheme
                        gameState.saveColorScheme()
                    }
                )) {
                    ForEach(TwentyFortyEightGameState.ColorScheme.allCases) { scheme in
                        Text(scheme.rawValue).tag(scheme)
                    }
                }
                .pickerStyle(.menu)
                .tint(.blue)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Score and Controls Row
            HStack(spacing: 12) {
                // Best Score
                VStack(spacing: 4) {
                    Text("BEST")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    Text("\(gameState.bestScore)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                // Moves Counter
                VStack(spacing: 4) {
                    Text("MOVES")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    Text("\(gameState.moveCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Spacer()
                
                // Undo Button
                Button(action: {
                    SoundManager.shared.play(.click)
                    HapticManager.shared.impact(style: .light)
                    withAnimation {
                        gameState.undo()
                    }
                }) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(gameState.canUndo ? .blue : .gray.opacity(0.3))
                }
                .disabled(!gameState.canUndo)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            Spacer()
            
            // Game Grid
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height) - 32
                let tileSize = (size - 20) / 4 // 4 tiles + 5 gaps of 4pt
                
                ZStack {
                    // Background grid
                    VStack(spacing: 4) {
                        ForEach(0..<4, id: \.self) { _ in
                            HStack(spacing: 4) {
                                ForEach(0..<4, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: tileSize, height: tileSize)
                                }
                            }
                        }
                    }
                    .frame(width: size, height: size)
                    
                    // Tiles
                    VStack(spacing: 4) {
                        ForEach(0..<4, id: \.self) { row in
                            HStack(spacing: 4) {
                                ForEach(0..<4, id: \.self) { col in
                                    TileView(
                                        value: gameState.grid[row][col],
                                        size: tileSize,
                                        colorScheme: gameState.colorScheme
                                    )
                                }
                            }
                        }
                    }
                    .frame(width: size, height: size)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .aspectRatio(1, contentMode: .fit)
            .padding(.horizontal, 16)
            
            Spacer()
            
            // New Game Button
            Button(action: {
                SoundManager.shared.play(.tap)
                withAnimation {
                    gameState.startNewGame()
                }
            }) {
                Text("New Game")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            // Game Over Overlay
            if gameState.isGameOver {
                GameOverView(
                    message: "Game Over!",
                    isSuccess: false,
                    onPlayAgain: {
                        withAnimation {
                            gameState.startNewGame()
                        }
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(Color.cardBackground)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    handleSwipe(value: value)
                }
        )
        #if os(macOS)
        .focusable()
        .onKeyPress { press in
            handleKeyPress(press)
        }
        #endif
        .onChange(of: gameState.hasWon) { _, won in
            if won && !gameState.hasShownWinMessage {
                SoundManager.shared.play(.win)
                HapticManager.shared.notification(type: .success)
                showWinAlert = true
                gameState.hasShownWinMessage = true
            }
        }
        .alert("You Win! 🎉", isPresented: $showWinAlert) {
            Button("Keep Playing") {
                // Continue playing
            }
            Button("New Game") {
                withAnimation {
                    gameState.startNewGame()
                }
            }
        } message: {
            Text("You reached 2048! You can keep playing or start a new game.")
        }
    }
    
    // MARK: - Input Handling
    
    private func handleSwipe(value: DragGesture.Value) {
        let horizontalAmount = value.translation.width
        let verticalAmount = value.translation.height
        
        let direction: TwentyFortyEightGameState.Direction
        
        if abs(horizontalAmount) > abs(verticalAmount) {
            // Horizontal swipe
            direction = horizontalAmount > 0 ? .right : .left
        } else {
            // Vertical swipe
            direction = verticalAmount > 0 ? .down : .up
        }
        
        withAnimation(.easeOut(duration: 0.2)) {
            if gameState.move(direction: direction) {
                SoundManager.shared.play(.tap)
                HapticManager.shared.impact(style: .light)
            }
        }
    }
    
    #if os(macOS)
    private func handleKeyPress(_ press: KeyPress) -> KeyPress.Result {
        guard !gameState.isGameOver else { return .ignored }
        
        // Check for undo (Z key or ⌘Z)
        if press.characters == "z" {
            if gameState.canUndo {
                SoundManager.shared.play(.click)
                withAnimation {
                    gameState.undo()
                }
                return .handled
            }
            return .ignored
        }
        
        let direction: TwentyFortyEightGameState.Direction?
        
        switch press.key {
        case .upArrow:
            direction = .up
        case .downArrow:
            direction = .down
        case .leftArrow:
            direction = .left
        case .rightArrow:
            direction = .right
        default:
            direction = nil
        }
        
        if let direction = direction {
            withAnimation(.easeOut(duration: 0.2)) {
                if gameState.move(direction: direction) {
                    SoundManager.shared.play(.tap)
                }
            }
            return .handled
        }
        
        return .ignored
    }
    #endif
}

// MARK: - Tile View

struct TileView: View {
    let value: Int?
    let size: CGFloat
    let colorScheme: TwentyFortyEightGameState.ColorScheme
    
    init(value: Int?, size: CGFloat, colorScheme: TwentyFortyEightGameState.ColorScheme = .classic) {
        self.value = value
        self.size = size
        self.colorScheme = colorScheme
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme.tileColor(for: value))
            
            if let value = value {
                Text("\(value)")
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme.textColor(for: value))
            }
        }
        .frame(width: size, height: size)
    }
    
    private var fontSize: CGFloat {
        guard let value = value else {
            return size * 0.5
        }
        
        let digitCount = String(value).count
        switch digitCount {
        case 1, 2:
            return size * 0.5
        case 3:
            return size * 0.4
        case 4:
            return size * 0.35
        default:
            return size * 0.3
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        r = (int >> 16) & 0xFF
        g = (int >> 8) & 0xFF
        b = int & 0xFF
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: 1
        )
    }
}

#Preview {
    TwentyFortyEightView()
}
