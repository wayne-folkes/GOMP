import SwiftUI
import Combine
import CoreServices

/// Difficulty levels for the Dictionary game.
enum Difficulty: String, CaseIterable, Identifiable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var id: String { self.rawValue }
}

/// Represents a word with its definition.
struct Word: Identifiable, Equatable {
    let id = UUID()
    let term: String
    let definition: String
    let difficulty: Difficulty
}

/// Game logic and state management for the Dictionary definition quiz.
///
/// This class implements a vocabulary quiz game where players match words to their definitions.
/// It features three difficulty levels and offline word definition lookup using Apple's Dictionary Services.
///
/// ## Features
/// - **Three Difficulty Levels**: Easy (common words), Medium (interesting vocabulary), Hard (advanced vocabulary)
/// - **Multiple Choice**: 4 definition options per word
/// - **Offline Dictionary**: Uses Apple's Dictionary Services API for clean, concise definitions
/// - **Local Fallback**: Uses hardcoded definitions if system dictionary lookup fails
/// - **10-Second Timer**: Automatic progression via CountdownButton
///
/// ## Dictionary Services Flow
/// 1. Select random word from appropriate difficulty level
/// 2. Query Apple's Dictionary Services for system definition
/// 3. If found: Parse and clean the definition (remove examples, pronunciation)
/// 4. If not found: Fall back to hardcoded definition in word bank
/// 5. Generate 3 wrong answer options from other words
///
/// ## Usage
/// ```swift
/// @StateObject private var gameState = DictionaryGameState()
///
/// // Change difficulty
/// gameState.setDifficulty(.hard)
///
/// // Player selects an answer
/// gameState.checkAnswer(definition)
///
/// // Move to next word (auto-called by timer or manual)
/// gameState.nextQuestion()
/// ```
///
/// - Important: Must be accessed from the main actor/thread
@MainActor
class DictionaryGameState: ObservableObject {
    /// Current word being quizzed
    @Published var currentWord: Word?
    
    /// Four definition options (one correct, three wrong)
    @Published var options: [String] = []
    
    /// Current score (points for correct answers)
    @Published var score: Int = 0
    
    /// Whether the game session has ended
    @Published var isGameOver: Bool = false
    
    /// Feedback color for selected answer (green=correct, red=wrong)
    @Published var feedbackColor: Color = .clear
    
    /// The definition the player selected (nil if not yet answered)
    @Published var selectedOption: String? = nil
    
    /// Current difficulty level
    @Published var difficulty: Difficulty = .medium
    
    /// Hardcoded word bank for Easy, Medium, and fallback scenarios.
    /// Contains 30 words across three difficulty levels (10 each).
    private var allWords: [Word] = [
        // Easy
        Word(term: "Happy", definition: "Feeling or showing pleasure or contentment.", difficulty: .easy),
        Word(term: "Strong", definition: "Having the power to move heavy weights or perform other physically demanding tasks.", difficulty: .easy),
        Word(term: "Bright", definition: "Giving out or reflecting a lot of light; shining.", difficulty: .easy),
        Word(term: "Quick", definition: "Moving fast or doing something in a short time.", difficulty: .easy),
        Word(term: "Quiet", definition: "Making little or no noise.", difficulty: .easy),
        Word(term: "Funny", definition: "Causing laughter or amusement; humorous.", difficulty: .easy),
        Word(term: "Simple", definition: "Easily understood or done; presenting no difficulty.", difficulty: .easy),
        Word(term: "Brave", definition: "Ready to face and endure danger or pain; showing courage.", difficulty: .easy),
        Word(term: "Calm", definition: "Not showing or feeling nervousness, anger, or other emotions.", difficulty: .easy),
        Word(term: "Wise", definition: "Having or showing experience, knowledge, and good judgment.", difficulty: .easy),
        
        // Medium
        Word(term: "Ephemeral", definition: "Lasting for a very short time.", difficulty: .medium),
        Word(term: "Serendipity", definition: "The occurrence of events by chance in a happy or beneficial way.", difficulty: .medium),
        Word(term: "Petrichor", definition: "A pleasant smell that frequently accompanies the first rain after a long period of warm, dry weather.", difficulty: .medium),
        Word(term: "Mellifluous", definition: "A sound that is sweet and musical; pleasant to hear.", difficulty: .medium),
        Word(term: "Ineffable", definition: "Too great or extreme to be expressed or described in words.", difficulty: .medium),
        Word(term: "Sonder", definition: "The realization that each random passerby is living a life as vivid and complex as your own.", difficulty: .medium),
        Word(term: "Limerence", definition: "The state of being infatuated or obsessed with another person.", difficulty: .medium),
        Word(term: "Sonorous", definition: "Imposing deep and full sound.", difficulty: .medium),
        Word(term: "Solitude", definition: "The state or situation of being alone.", difficulty: .medium),
        Word(term: "Aurora", definition: "A natural light display in the Earth's sky.", difficulty: .medium),
        
        // Hard
        Word(term: "Vellichor", definition: "The strange wistfulness of used bookstores.", difficulty: .hard),
        Word(term: "Defenestration", definition: "The act of throwing someone or something out of a window.", difficulty: .hard),
        Word(term: "Phosphenes", definition: "The moving patterns you see when you rub your eyes.", difficulty: .hard),
        Word(term: "Apricity", definition: "The warmth of the sun in winter.", difficulty: .hard),
        Word(term: "Cromulent", definition: "Acceptable or adequate.", difficulty: .hard),
        Word(term: "Embiggen", definition: "To make bigger or more expansive.", difficulty: .hard),
        Word(term: "Ubiquitous", definition: "Present, appearing, or found everywhere.", difficulty: .hard),
        Word(term: "Pernicious", definition: "Having a harmful effect, especially in a gradual or subtle way.", difficulty: .hard),
        Word(term: "Esoteric", definition: "Intended for or likely to be understood by only a small number of people.", difficulty: .hard),
        Word(term: "Obfuscate", definition: "Render obscure, unclear, or unintelligible.", difficulty: .hard)
    ]
    
    init(startImmediately: Bool = true) {
        if startImmediately {
            startNewGame()
        }
    }
    
    func setDifficulty(_ newDifficulty: Difficulty) {
        difficulty = newDifficulty
        startNewGame()
    }
    
    func startNewGame() {
        score = 0
        isGameOver = false
        nextQuestion()
    }
    
    func nextQuestion() {
        feedbackColor = .clear
        selectedOption = nil
        
        // Select random word from appropriate difficulty
        let filteredWords = allWords.filter { $0.difficulty == difficulty }
        guard let selectedWord = filteredWords.randomElement() else { 
            return
        }
        
        // Try to get system dictionary definition
        if let systemDefinition = DictionaryServicesHelper.getCleanDefinition(for: selectedWord.term.lowercased()) {
            // Use system definition (cleaner, more concise)
            let wordWithSystemDef = Word(
                term: selectedWord.term, 
                definition: systemDefinition, 
                difficulty: difficulty
            )
            currentWord = wordWithSystemDef
        } else {
            // Fallback to hardcoded definition
            currentWord = selectedWord
        }
        
        // Generate options as before
        generateOptions(for: currentWord!, pool: filteredWords)
    }
    
    func loadLocalQuestion() {
        // Kept for backward compatibility, but now just calls nextQuestion()
        nextQuestion()
    }
    
    private func generateOptions(for word: Word, pool: [Word]) {
        var distractorDefinitions = pool.filter { $0.id != word.id }.map { $0.definition }
        
        // Fallback to all words if pool is small
        if distractorDefinitions.count < 3 {
             distractorDefinitions = allWords.filter { $0.id != word.id }.map { $0.definition }
        }
        
        distractorDefinitions.shuffle()
        
        var currentOptions = Array(distractorDefinitions.prefix(3))
        currentOptions.append(word.definition)
        options = currentOptions.shuffled()
    }

    func checkAnswer(_ answer: String) {
        guard let currentWord = currentWord else { return }
        selectedOption = answer
        
        let isCorrect = answer == currentWord.definition
        if isCorrect {
            score += 1
            feedbackColor = .green
            SoundManager.shared.play(.success)
            HapticManager.shared.notification(type: .success)
        } else {
            feedbackColor = .red
            SoundManager.shared.play(.lose)
            HapticManager.shared.notification(type: .error)
        }
        
        // Record statistics after checking the answer
        GameStatistics.shared.recordDictionaryGame(score: score)
    }
}

