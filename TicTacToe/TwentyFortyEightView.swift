//
//  TwentyFortyEightView.swift
//  GOMP
//
//  Created on 2/1/26.
//

import SwiftUI

// MARK: - 2048 Grid Component
private struct GameGrid2048: View {
    let gameState: TwentyFortyEightGameState
    
    var body: some View {
        GeometryReader { geometry in
            let gridSize = calculateGridSize(from: geometry.size)
            let tileSize = calculateTileSize(gridSize: gridSize)
            
            ZStack {
                backgroundGrid(tileSize: tileSize, gridSize: gridSize)
                tileGrid(tileSize: tileSize, gridSize: gridSize)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(.horizontal, 16)
    }
    
    private func calculateGridSize(from size: CGSize) -> CGFloat {
        let rawMin = min(size.width, size.height)
        let clampedMin = rawMin.isFinite ? max(rawMin, 0) : 0
        return max(clampedMin - 32, 0)
    }
    
    private func calculateTileSize(gridSize: CGFloat) -> CGFloat {
        let computedTile = (gridSize - 20) / 4
        return computedTile.isFinite ? max(computedTile, 0) : 0
    }
    
    private func backgroundGrid(tileSize: CGFloat, gridSize: CGFloat) -> some View {
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
        .frame(width: gridSize, height: gridSize)
    }
    
    private func tileGrid(tileSize: CGFloat, gridSize: CGFloat) -> some View {
        VStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { col in
                        TileView(
                            value: gameState.grid[row][col],
                            size: tileSize,
                            colorScheme: gameState.colorScheme,
                            isMerged: gameState.lastMergedPositions.contains(where: { $0.0 == row && $0.1 == col }),
                            isNew: gameState.lastNewTilePosition?.0 == row && gameState.lastNewTilePosition?.1 == col
                        )
                    }
                }
            }
        }
        .frame(width: gridSize, height: gridSize)
    }
}

// MARK: - Score Header Component
private struct ScoreHeaderView: View {
    let bestScore: Int
    let moveCount: Int
    let canUndo: Bool
    let onUndo: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            bestScoreCard
            movesCard
            Spacer()
            undoButton
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private var bestScoreCard: some View {
        VStack(spacing: 4) {
            Text("BEST")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            Text("\(bestScore)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var movesCard: some View {
        VStack(spacing: 4) {
            Text("MOVES")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            Text("\(moveCount)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var undoButton: some View {
        Button(action: onUndo) {
            Image(systemName: "arrow.uturn.backward.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(canUndo ? .blue : .gray.opacity(0.3))
        }
        .disabled(!canUndo)
        .buttonStyle(.plain)
    }
}

struct TwentyFortyEightView: View {
    @StateObject private var gameState = TwentyFortyEightGameState()
    @State private var showWinAlert = false
    @State private var mergedTiles: Set<String> = []
    @State private var newTile: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            themePickerSection
            scoreHeader
            Spacer()
            gameGrid
            Spacer()
            newGameButton
            gameOverOverlay
        }
        .background(Color.cardBackground)
        .configureNavigation()
        .addSwipeGesture(onSwipe: handleSwipe)
        .addKeyboardSupport(onKeyPress: handleKeyPress)
        .handleWinState(hasWon: gameState.hasWon, showWinAlert: $showWinAlert, onWin: handleWin)
        .alert("You Win! 🎉", isPresented: $showWinAlert) {
            Button("Keep Playing") { }
            Button("New Game") {
                withAnimation {
                    gameState.startNewGame()
                }
            }
        } message: {
            Text("You reached 2048! You can keep playing or start a new game.")
        }
    }
    
    private var headerSection: some View {
        GameHeaderView(
            title: "2048",
            score: gameState.score,
            scoreColor: .primary
        )
        .padding(.top, 16)
    }
    
    private var themePickerSection: some View {
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
    }
    
    private var scoreHeader: some View {
        ScoreHeaderView(
            bestScore: gameState.bestScore,
            moveCount: gameState.moveCount,
            canUndo: gameState.canUndo,
            onUndo: {
                SoundManager.shared.play(.click)
                HapticManager.shared.impact(style: .light)
                withAnimation {
                    gameState.undo()
                }
            }
        )
    }
    
    private var gameGrid: some View {
        GameGrid2048(gameState: gameState)
    }
    
    private var newGameButton: some View {
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
    }
    
    @ViewBuilder
    private var gameOverOverlay: some View {
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
    
    private func handleWin() {
        if !gameState.hasShownWinMessage {
            SoundManager.shared.play(.win)
            HapticManager.shared.notification(type: .success)
            showWinAlert = true
            gameState.hasShownWinMessage = true
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
        
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
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
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
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
    let isMerged: Bool
    let isNew: Bool
    
    init(value: Int?, size: CGFloat, colorScheme: TwentyFortyEightGameState.ColorScheme = .classic, isMerged: Bool = false, isNew: Bool = false) {
        self.value = value
        self.size = size
        self.colorScheme = colorScheme
        self.isMerged = isMerged
        self.isNew = isNew
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
        .scaleEffect(isMerged ? 1.15 : (isNew ? 0.1 : 1.0))
        .opacity(isNew ? 0.0 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isMerged)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isNew)
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

// MARK: - View Modifiers for TwentyFortyEightView
private extension View {
    func configureNavigation() -> some View {
        self
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(true)
        #endif
        #if canImport(UIKit)
        .disableSwipeBack()
        #endif
    }
    
    func addSwipeGesture(onSwipe: @escaping (DragGesture.Value) -> Void) -> some View {
        self.gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    onSwipe(value)
                }
        )
    }
    
    func addKeyboardSupport(onKeyPress: @escaping (KeyPress) -> KeyPress.Result) -> some View {
        self
        #if os(macOS)
        .focusable()
        .onKeyPress { press in
            onKeyPress(press)
        }
        #endif
    }
    
    func handleWinState(hasWon: Bool, showWinAlert: Binding<Bool>, onWin: @escaping () -> Void) -> some View {
        self.onChange(of: hasWon) { _, won in
            if won && !showWinAlert.wrappedValue {
                onWin()
            }
        }
    }
}

#Preview {
    TwentyFortyEightView()
}

