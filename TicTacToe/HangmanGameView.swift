import SwiftUI

// MARK: - Letter Keyboard Component
private struct LetterKeyboard: View {
    let guessedLetters: Set<Character>
    let currentWord: String
    let isGameOver: Bool
    let onLetterTap: (Character) -> Void
    
    var body: some View {
        GeometryReader { geo in
            let keyboardMetrics = calculateKeyboardMetrics(availableWidth: geo.size.width)
            
            VStack(spacing: 10) {
                keyboardRow(letters: Array("QWERTYUIOP"), keyWidth: keyboardMetrics.keyWidth)
                keyboardRow(letters: Array("ASDFGHJKL"), keyWidth: keyboardMetrics.keyWidth)
                    .frame(width: keyboardMetrics.row2Width)
                    .frame(maxWidth: .infinity)
                keyboardRow(letters: Array("ZXCVBNM"), keyWidth: keyboardMetrics.keyWidth)
                    .frame(width: keyboardMetrics.row3Width)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 3 * 40 + 2 * 10)
    }
    
    private func calculateKeyboardMetrics(availableWidth: CGFloat) -> KeyboardMetrics {
        let spacing: CGFloat = 6
        let keyWidth = floor((availableWidth - spacing * 9) / 10)
        let row2Width = CGFloat(9) * keyWidth + CGFloat(8) * spacing
        let row3Width = CGFloat(7) * keyWidth + CGFloat(6) * spacing
        return KeyboardMetrics(keyWidth: keyWidth, row2Width: row2Width, row3Width: row3Width)
    }
    
    private func keyboardRow(letters: [Character], keyWidth: CGFloat) -> some View {
        HStack(spacing: 6) {
            ForEach(letters, id: \.self) { letter in
                letterButton(letter, keyWidth: keyWidth)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func letterButton(_ letter: Character, keyWidth: CGFloat) -> some View {
        let isGuessed = guessedLetters.contains(letter)
        let isInWord = currentWord.contains(letter)
        
        return LetterButtonView(
            letter: letter,
            keyWidth: keyWidth,
            isGuessed: isGuessed,
            isInWord: isInWord,
            isGameOver: isGameOver,
            onTap: {
                SoundManager.shared.play(.click)
                onLetterTap(letter)
            }
        )
    }
    
    private struct KeyboardMetrics {
        let keyWidth: CGFloat
        let row2Width: CGFloat
        let row3Width: CGFloat
    }
}

struct HangmanGameView: View {
    @StateObject private var gameState = HangmanGameState()
    @ObservedObject private var sessionTracker = SessionTimeTracker.shared
    @State private var showConfetti = false
    @State private var confettiTask: Task<Void, Never>?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerSection
                statsSection
                categoryPicker
                drawingSection
                wordDisplay
                letterKeyboard
                gameOverSection
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.cardBackground)
        .configureHangmanNavigation()
        .overlay(alignment: .top) {
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
        }
        .onChange(of: gameState.hasWon) { _, won in
            handleWinChange(won)
        }
        .onChange(of: gameState.isGameOver) { _, isOver in
            handleGameOverChange(isOver)
        }
        .onAppear {
            sessionTracker.startSession(for: "Hangman")
        }
        .onDisappear {
            confettiTask?.cancel()
            sessionTracker.endSession()
        }
        #if os(macOS)
        .focusable()
        .onKeyPress { press in
            handleKeyPress(press)
        }
        #endif
        #if canImport(UIKit)
        .disableSwipeBack()
        #endif
    }
    
    private var headerSection: some View {
        GameHeaderView(
            title: "Hangman",
            score: gameState.score
        )
    }
    
    private var statsSection: some View {
        HStack(spacing: 30) {
            VStack {
                Text("Won")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(gameState.gamesWon)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.successColor)
            }
            
            VStack {
                Text("Lost")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(gameState.gamesLost)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.errorColor)
            }
        }
    }
    
    private var drawingSection: some View {
        HangmanDrawingView(wrongGuesses: gameState.wrongGuesses)
            .frame(height: 250)
    }
    
    @ViewBuilder
    private var gameOverSection: some View {
        if gameState.isGameOver {
            GameOverView(
                message: gameState.hasWon ? "🎉 You Won!" : "😢 Game Over\nThe word was: \(gameState.currentWord)",
                isSuccess: gameState.hasWon,
                onPlayAgain: {
                    confettiTask?.cancel()
                    showConfetti = false
                    gameState.startNewGame()
                },
                secondaryButtonTitle: "Reset Stats",
                onSecondaryAction: {
                    gameState.resetStats()
                }
            )
        }
    }
    
    private func handleWinChange(_ won: Bool) {
        if won {
            SoundManager.shared.play(.win)
            HapticManager.shared.notification(type: .success)
            showConfetti = true
            confettiTask?.cancel()
            confettiTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }
                showConfetti = false
            }
        }
    }
    
    private func handleGameOverChange(_ isOver: Bool) {
        if isOver && !gameState.hasWon {
            SoundManager.shared.play(.lose)
            HapticManager.shared.notification(type: .error)
        }
    }
    
    #if os(macOS)
    /// Handles keyboard input on macOS for letter guessing
    private func handleKeyPress(_ press: KeyPress) -> KeyPress.Result {
        // Extract first character from key press
        guard let character = press.characters.first else {
            return .ignored
        }
        
        // Convert to uppercase for consistency
        let letter = Character(character.uppercased())
        
        // Validate: must be a letter (A-Z)
        guard letter.isLetter, letter.isASCII else {
            return .ignored
        }
        
        // Ignore if game is over
        guard !gameState.isGameOver else {
            return .ignored
        }
        
        // Ignore if letter already guessed
        guard !gameState.guessedLetters.contains(letter) else {
            return .ignored
        }
        
        // Play sound and make the guess
        SoundManager.shared.play(.click)
        gameState.guessLetter(letter)
        
        return .handled
    }
    #endif
    
    private var categoryPicker: some View {
        Picker("Category", selection: $gameState.selectedCategory) {
            ForEach(WordCategory.allCases) { category in
                Text(category.rawValue).tag(category)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .onChange(of: gameState.selectedCategory) { _, newCategory in
            gameState.setCategory(newCategory)
        }
    }
    
    private var wordDisplay: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(gameState.getDisplayWord())
                .font(.largeTitle)
                .fontWeight(.bold)
                .fontDesign(.monospaced)
                .tracking(4) // Reduced from 8 to 4 for better fit
                .padding(16)
        }
        .frame(maxWidth: .infinity)
        .background(Color.elevatedCardBackground.opacity(0.6))
        .cornerRadius(12)
    }
    
    private var letterKeyboard: some View {
        LetterKeyboard(
            guessedLetters: gameState.guessedLetters,
            currentWord: gameState.currentWord,
            isGameOver: gameState.isGameOver,
            onLetterTap: { letter in
                gameState.guessLetter(letter)
            }
        )
    }
}

// Separate button view to support hover state
struct LetterButtonView: View {
    let letter: Character
    let keyWidth: CGFloat
    let isGuessed: Bool
    let isInWord: Bool
    let isGameOver: Bool
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            Text(String(letter))
                .font(.headline)
                .fontWeight(.bold)
                .frame(width: keyWidth, height: 40)
                .background(backgroundColor)
                .foregroundColor(isGuessed ? .white : .primary)
                .cornerRadius(8)
                .scaleEffect(isHovered && !isGuessed && !isGameOver ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isHovered)
        }
        .disabled(isGuessed || isGameOver)
        #if os(macOS)
        .onHover { hovering in
            isHovered = hovering
        }
        #endif
    }
    
    private var backgroundColor: Color {
        if isGuessed {
            return isInWord ? Color.successColor.opacity(0.7) : Color.errorColor.opacity(0.7)
        }
        #if os(macOS)
        return Color.hangmanAccent.opacity(isHovered ? 0.4 : 0.3)
        #else
        return Color.hangmanAccent.opacity(0.3)
        #endif
    }
}

// Stick figure drawing view
struct HangmanDrawingView: View {
    let wrongGuesses: Int
    
    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            
            // Draw base and pole (always visible)
            drawGallows(context: context, width: width, height: height)
            
            // Draw body parts based on wrong guesses
            if wrongGuesses >= 1 {
                drawHead(context: context, width: width, height: height)
            }
            if wrongGuesses >= 2 {
                drawBody(context: context, width: width, height: height)
            }
            if wrongGuesses >= 3 {
                drawLeftArm(context: context, width: width, height: height)
            }
            if wrongGuesses >= 4 {
                drawRightArm(context: context, width: width, height: height)
            }
            if wrongGuesses >= 5 {
                drawLeftLeg(context: context, width: width, height: height)
            }
            if wrongGuesses >= 6 {
                drawRightLeg(context: context, width: width, height: height)
            }
            if wrongGuesses >= 7 {
                drawFace(context: context, width: width, height: height, sad: false)
            }
            if wrongGuesses >= 8 {
                drawFace(context: context, width: width, height: height, sad: true)
            }
        }
    }
    
    private func drawGallows(context: GraphicsContext, width: CGFloat, height: CGFloat) {
        var path = Path()
        
        // Base
        path.move(to: CGPoint(x: width * 0.1, y: height * 0.95))
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.95))
        
        // Vertical pole
        path.move(to: CGPoint(x: width * 0.2, y: height * 0.95))
        path.addLine(to: CGPoint(x: width * 0.2, y: height * 0.1))
        
        // Horizontal beam
        path.move(to: CGPoint(x: width * 0.2, y: height * 0.1))
        path.addLine(to: CGPoint(x: width * 0.6, y: height * 0.1))
        
        // Rope
        path.move(to: CGPoint(x: width * 0.6, y: height * 0.1))
        path.addLine(to: CGPoint(x: width * 0.6, y: height * 0.2))
        
        context.stroke(path, with: .color(.brown), lineWidth: 3)
    }
    
    private func drawHead(context: GraphicsContext, width: CGFloat, height: CGFloat) {
        let center = CGPoint(x: width * 0.6, y: height * 0.27)
        let radius = height * 0.07
        
        var path = Path()
        path.addEllipse(in: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        
        context.stroke(path, with: .color(.black), lineWidth: 2)
    }
    
    private func drawBody(context: GraphicsContext, width: CGFloat, height: CGFloat) {
        var path = Path()
        path.move(to: CGPoint(x: width * 0.6, y: height * 0.34))
        path.addLine(to: CGPoint(x: width * 0.6, y: height * 0.55))
        
        context.stroke(path, with: .color(.black), lineWidth: 2)
    }
    
    private func drawLeftArm(context: GraphicsContext, width: CGFloat, height: CGFloat) {
        var path = Path()
        path.move(to: CGPoint(x: width * 0.6, y: height * 0.4))
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.48))
        
        context.stroke(path, with: .color(.black), lineWidth: 2)
    }
    
    private func drawRightArm(context: GraphicsContext, width: CGFloat, height: CGFloat) {
        var path = Path()
        path.move(to: CGPoint(x: width * 0.6, y: height * 0.4))
        path.addLine(to: CGPoint(x: width * 0.7, y: height * 0.48))
        
        context.stroke(path, with: .color(.black), lineWidth: 2)
    }
    
    private func drawLeftLeg(context: GraphicsContext, width: CGFloat, height: CGFloat) {
        var path = Path()
        path.move(to: CGPoint(x: width * 0.6, y: height * 0.55))
        path.addLine(to: CGPoint(x: width * 0.52, y: height * 0.7))
        
        context.stroke(path, with: .color(.black), lineWidth: 2)
    }
    
    private func drawRightLeg(context: GraphicsContext, width: CGFloat, height: CGFloat) {
        var path = Path()
        path.move(to: CGPoint(x: width * 0.6, y: height * 0.55))
        path.addLine(to: CGPoint(x: width * 0.68, y: height * 0.7))
        
        context.stroke(path, with: .color(.black), lineWidth: 2)
    }
    
    private func drawFace(context: GraphicsContext, width: CGFloat, height: CGFloat, sad: Bool) {
        let centerX = width * 0.6
        let centerY = height * 0.27
        let eyeOffset = height * 0.02
        
        // Eyes
        var eyePath = Path()
        if sad {
            // X eyes for final stage
            eyePath.move(to: CGPoint(x: centerX - eyeOffset - 3, y: centerY - 3))
            eyePath.addLine(to: CGPoint(x: centerX - eyeOffset + 3, y: centerY + 3))
            eyePath.move(to: CGPoint(x: centerX - eyeOffset + 3, y: centerY - 3))
            eyePath.addLine(to: CGPoint(x: centerX - eyeOffset - 3, y: centerY + 3))
            
            eyePath.move(to: CGPoint(x: centerX + eyeOffset - 3, y: centerY - 3))
            eyePath.addLine(to: CGPoint(x: centerX + eyeOffset + 3, y: centerY + 3))
            eyePath.move(to: CGPoint(x: centerX + eyeOffset + 3, y: centerY - 3))
            eyePath.addLine(to: CGPoint(x: centerX + eyeOffset - 3, y: centerY + 3))
        } else {
            // Simple dot eyes
            eyePath.addEllipse(in: CGRect(x: centerX - eyeOffset - 2, y: centerY - 2, width: 4, height: 4))
            eyePath.addEllipse(in: CGRect(x: centerX + eyeOffset - 2, y: centerY - 2, width: 4, height: 4))
        }
        
        context.stroke(eyePath, with: .color(.black), lineWidth: 1.5)
        
        if sad {
            // Sad mouth
            var mouthPath = Path()
            mouthPath.move(to: CGPoint(x: centerX - eyeOffset, y: centerY + eyeOffset * 2))
            mouthPath.addQuadCurve(
                to: CGPoint(x: centerX + eyeOffset, y: centerY + eyeOffset * 2),
                control: CGPoint(x: centerX, y: centerY + eyeOffset)
            )
            context.stroke(mouthPath, with: .color(.black), lineWidth: 1.5)
        }
    }
}

// MARK: - View Modifiers for HangmanGameView
private extension View {
    func configureHangmanNavigation() -> some View {
        self
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    HangmanGameView()
}

