import SwiftUI

struct HangmanGameView: View {
    @StateObject private var gameState = HangmanGameState()
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header with score
                headerView
                
                // Category selector
                categoryPicker
                
                // Stick figure drawing
                HangmanDrawingView(wrongGuesses: gameState.wrongGuesses)
                    .frame(height: 250)
                
                // Word display
                wordDisplay
                
                // Letter keyboard
                letterKeyboard
                
                // Game status and controls
                gameControls
                
                Spacer()
            }
            .padding(.top, 60)
            .padding(.horizontal)
            
            if showConfetti {
                ConfettiView()
            }
        }
        .onChange(of: gameState.hasWon) { _, won in
            if won {
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showConfetti = false
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 5) {
            Text("Hangman")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            HStack(spacing: 30) {
                VStack {
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(gameState.score)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                VStack {
                    Text("Won")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(gameState.gamesWon)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                VStack {
                    Text("Lost")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(gameState.gamesLost)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private var categoryPicker: some View {
        Picker("Category", selection: $gameState.selectedCategory) {
            ForEach(WordCategory.allCases) { category in
                Text(category.rawValue).tag(category)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: gameState.selectedCategory) { _, newCategory in
            gameState.setCategory(newCategory)
        }
    }
    
    private var wordDisplay: some View {
        Text(gameState.getDisplayWord())
            .font(.system(size: 36, weight: .bold, design: .monospaced))
            .tracking(8)
            .padding()
            .background(Color.white.opacity(0.8))
            .cornerRadius(10)
    }
    
    private var letterKeyboard: some View {
        VStack(spacing: 10) {
            // First row: A-I
            HStack(spacing: 8) {
                ForEach(Array("ABCDEFGHI"), id: \.self) { letter in
                    letterButton(letter)
                }
            }
            
            // Second row: J-R
            HStack(spacing: 8) {
                ForEach(Array("JKLMNOPQR"), id: \.self) { letter in
                    letterButton(letter)
                }
            }
            
            // Third row: S-Z
            HStack(spacing: 8) {
                ForEach(Array("STUVWXYZ"), id: \.self) { letter in
                    letterButton(letter)
                }
            }
        }
    }
    
    private func letterButton(_ letter: Character) -> some View {
        let isGuessed = gameState.guessedLetters.contains(letter)
        let isInWord = gameState.currentWord.contains(letter)
        
        return Button(action: {
            gameState.guessLetter(letter)
        }) {
            Text(String(letter))
                .font(.system(size: 18, weight: .bold))
                .frame(width: 35, height: 40)
                .background(
                    isGuessed
                        ? (isInWord ? Color.green.opacity(0.6) : Color.red.opacity(0.6))
                        : Color.blue.opacity(0.3)
                )
                .foregroundColor(isGuessed ? .white : .primary)
                .cornerRadius(8)
        }
        .disabled(isGuessed || gameState.isGameOver)
    }
    
    private var gameControls: some View {
        VStack(spacing: 15) {
            if gameState.isGameOver {
                VStack(spacing: 10) {
                    Text(gameState.hasWon ? "🎉 You Won!" : "😢 Game Over")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(gameState.hasWon ? .green : .red)
                    
                    if !gameState.hasWon {
                        Text("The word was: \(gameState.currentWord)")
                            .font(.headline)
                    }
                }
            }
            
            Button(action: {
                showConfetti = false
                gameState.startNewGame()
            }) {
                Text("New Game")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            Button(action: {
                gameState.resetStats()
            }) {
                Text("Reset Stats")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        }
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

#Preview {
    HangmanGameView()
}
