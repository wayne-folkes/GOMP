import SwiftUI

// MARK: - Memory Card Grid Component
private struct MemoryCardGrid: View {
    let cards: [MemoryCard]
    let geometry: GeometryProxy
    let shakeOffsets: [UUID: CGFloat]
    let highlightedMismatchIds: Set<UUID>
    let isProcessingMismatch: Bool
    let onCardTap: (MemoryCard) -> Void
    
    var body: some View {
        let availableHeight = geometry.size.height
        let availableWidth = geometry.size.width
        
        if !availableHeight.isFinite || !availableWidth.isFinite || availableHeight <= 0 || availableWidth <= 0 {
            Color.clear
        } else {
            let gridMetrics = calculateGridMetrics(availableWidth: availableWidth, availableHeight: availableHeight)
            
            VStack(spacing: gridMetrics.spacing) {
                ForEach(0..<gridMetrics.rows, id: \.self) { row in
                    HStack(spacing: gridMetrics.spacing) {
                        ForEach(0..<gridMetrics.columns, id: \.self) { col in
                            cardAtPosition(row: row, col: col, metrics: gridMetrics)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func calculateGridMetrics(availableWidth: CGFloat, availableHeight: CGFloat) -> GridMetrics {
        let horizontalPadding: CGFloat = 32
        let spacing: CGFloat = 8
        let columns = 4
        let rows = 5
        
        let cardWidth = (availableWidth - horizontalPadding - (spacing * CGFloat(columns - 1))) / CGFloat(columns)
        let cardHeight = (availableHeight - (spacing * CGFloat(rows - 1))) / CGFloat(rows)
        
        let minCardWidth: CGFloat = 20
        let proposedWidth = min(cardWidth, cardHeight * 2/3)
        let safeWidth = proposedWidth.isFinite && proposedWidth > 0 ? max(proposedWidth, minCardWidth) : minCardWidth
        
        return GridMetrics(
            cardWidth: safeWidth,
            cardHeight: safeWidth * 3/2,
            spacing: spacing,
            columns: columns,
            rows: rows
        )
    }
    
    @ViewBuilder
    private func cardAtPosition(row: Int, col: Int, metrics: GridMetrics) -> some View {
        let index = row * metrics.columns + col
        if index < cards.count {
            let card = cards[index]
            CardView(
                card: card,
                isDisabled: isProcessingMismatch || card.isFaceUp || card.isMatched,
                isMismatched: highlightedMismatchIds.contains(card.id)
            )
            .frame(width: metrics.cardWidth, height: metrics.cardHeight)
            .offset(x: shakeOffsets[card.id] ?? 0)
            .onTapGesture {
                onCardTap(card)
            }
        }
    }
    
    private struct GridMetrics {
        let cardWidth: CGFloat
        let cardHeight: CGFloat
        let spacing: CGFloat
        let columns: Int
        let rows: Int
    }
}

struct MemoryGameView: View {
    @StateObject private var gameState = MemoryGameState()
    @ObservedObject private var sessionTracker = SessionTimeTracker.shared
    @State private var showConfetti = false
    @State private var confettiTask: Task<Void, Never>?
    @State private var shakeOffsets: [UUID: CGFloat] = [:]
    @State private var highlightedMismatchIds: Set<UUID> = []
    
    var body: some View {
        mainContent
            .background(Color.cardBackground)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .overlay(alignment: .top) {
                if showConfetti {
                    ConfettiView()
                        .ignoresSafeArea()
                }
            }
            .onChange(of: gameState.isGameOver) { _, newValue in
                handleGameOverChange(newValue)
            }
            .onAppear {
                sessionTracker.startSession(for: "Memory")
            }
            .onDisappear {
                confettiTask?.cancel()
                sessionTracker.endSession()
            }
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            headerView
            themeSelector
            cardGrid
            gameOverView
        }
    }
    
    private var headerView: some View {
        GameHeaderView(
            title: "Memory Game",
            score: gameState.score,
            scoreColor: .primary
        )
        .padding(.top, 16)
    }
    
    private var themeSelector: some View {
        HStack {
            Text("Theme:")
                .font(.headline)
            
            Picker("Theme", selection: Binding(
                get: { gameState.currentTheme },
                set: { gameState.toggleTheme($0) }
            )) {
                ForEach(MemoryGameState.MemoryTheme.allCases) { theme in
                    Text(theme.rawValue).tag(theme)
                }
            }
            .pickerStyle(.menu)
            .tint(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private var cardGrid: some View {
        GeometryReader { geometry in
            MemoryCardGrid(
                cards: gameState.cards,
                geometry: geometry,
                shakeOffsets: shakeOffsets,
                highlightedMismatchIds: highlightedMismatchIds,
                isProcessingMismatch: gameState.isProcessingMismatch,
                onCardTap: handleCardTap
            )
        }
        .padding(.horizontal, 16)
        .onChange(of: gameState.mismatchedCardIds) { _, ids in
            handleMismatch(ids)
        }
    }
    
    @ViewBuilder
    private var gameOverView: some View {
        if gameState.isGameOver {
            GameOverView(
                message: "🎉 Game Complete!",
                isSuccess: true,
                onPlayAgain: {
                    confettiTask?.cancel()
                    showConfetti = false
                    withAnimation {
                        gameState.startNewGame()
                    }
                }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
    
    private func handleCardTap(_ card: MemoryCard) {
        guard !gameState.isProcessingMismatch else { return }
        
        SoundManager.shared.play(.flip)
        HapticManager.shared.impact(style: .light)
        withAnimation(.easeInOut(duration: 0.5)) {
            gameState.choose(card)
        }
    }
    
    private func handleMismatch(_ ids: Set<UUID>) {
        guard !ids.isEmpty else {
            highlightedMismatchIds = []
            return
        }
        
        highlightedMismatchIds = ids
        
        for cardId in ids {
            withAnimation(.default.repeatCount(3).speed(6)) {
                shakeOffsets[cardId] = 10
            }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.5))
                shakeOffsets[cardId] = 0
            }
        }
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            highlightedMismatchIds = []
        }
    }
    
    private func handleGameOverChange(_ newValue: Bool) {
        if newValue {
            SoundManager.shared.play(.win)
            HapticManager.shared.notification(type: .success)
            withAnimation(.easeIn(duration: 0.3)) {
                showConfetti = true
            }
            confettiTask?.cancel()
            confettiTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(4))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.3)) {
                    showConfetti = false
                }
            }
        }
    }
}

struct CardView: View {
    let card: MemoryCard
    let isDisabled: Bool
    let isMismatched: Bool
    
    @State private var isHovered = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if card.isFaceUp || card.isMatched {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.elevatedCardBackground)
                    
                    // Red border for mismatched cards, normal border otherwise
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isMismatched ? Color.errorColor : Color.memoryAccent, lineWidth: isMismatched ? 4 : 2)
                        
                    Text(card.content)
                        .font(.system(size: geometry.size.width * 0.7))
                        .opacity(card.isMatched ? 0.5 : 1)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.memoryAccent, Color.memoryAccent.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(isHovered && !isDisabled ? 0.15 : 0.1), radius: isHovered && !isDisabled ? 4 : 2, y: 1)
                }
            }
            .rotation3DEffect(Angle.degrees(card.isFaceUp ? 0 : 180), axis: (x: 0, y: 1, z: 0))
            .scaleEffect(isHovered && !isDisabled ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            // Add red glow for mismatched cards
            .shadow(color: isMismatched ? Color.errorColor.opacity(0.8) : .clear, radius: isMismatched ? 12 : 0)
            .animation(.easeInOut(duration: 0.2), value: isMismatched)
            #if os(macOS)
            .onHover { hovering in
                isHovered = hovering
            }
            #endif
        }
    }
}

#Preview {
    MemoryGameView()
}
