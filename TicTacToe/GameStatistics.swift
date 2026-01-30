import Foundation
import Combine

/// Manages persistent storage of game statistics and user preferences
@MainActor
class GameStatistics: ObservableObject {
    static let shared = GameStatistics()
    
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Keys
    private enum Keys {
        // Tic-Tac-Toe
        static let ticTacToeGamesPlayed = "ticTacToeGamesPlayed"
        static let ticTacToeXWins = "ticTacToeXWins"
        static let ticTacToeOWins = "ticTacToeOWins"
        static let ticTacToeDraws = "ticTacToeDraws"
        
        // Memory Game
        static let memoryGamesPlayed = "memoryGamesPlayed"
        static let memoryGamesWon = "memoryGamesWon"
        static let memoryHighScore = "memoryHighScore"
        static let memoryPreferredTheme = "memoryPreferredTheme"
        
        // Dictionary Game
        static let dictionaryGamesPlayed = "dictionaryGamesPlayed"
        static let dictionaryHighScore = "dictionaryHighScore"
        static let dictionaryPreferredDifficulty = "dictionaryPreferredDifficulty"
        
        // Hangman
        static let hangmanGamesPlayed = "hangmanGamesPlayed"
        static let hangmanGamesWon = "hangmanGamesWon"
        static let hangmanGamesLost = "hangmanGamesLost"
        static let hangmanHighScore = "hangmanHighScore"
        static let hangmanPreferredCategory = "hangmanPreferredCategory"
        
        // User Preferences
        static let soundEnabled = "soundEnabled"
        static let hapticsEnabled = "hapticsEnabled"
    }
    
    // MARK: - Tic-Tac-Toe Statistics
    @Published var ticTacToeGamesPlayed: Int
    @Published var ticTacToeXWins: Int
    @Published var ticTacToeOWins: Int
    @Published var ticTacToeDraws: Int
    
    // MARK: - Memory Game Statistics
    @Published var memoryGamesPlayed: Int
    @Published var memoryGamesWon: Int
    @Published var memoryHighScore: Int
    @Published var memoryPreferredTheme: String
    
    // MARK: - Dictionary Game Statistics
    @Published var dictionaryGamesPlayed: Int
    @Published var dictionaryHighScore: Int
    @Published var dictionaryPreferredDifficulty: String
    
    // MARK: - Hangman Statistics
    @Published var hangmanGamesPlayed: Int
    @Published var hangmanGamesWon: Int
    @Published var hangmanGamesLost: Int
    @Published var hangmanHighScore: Int
    @Published var hangmanPreferredCategory: String
    
    // MARK: - User Preferences (save immediately for settings)
    @Published var soundEnabled: Bool {
        didSet { userDefaults.set(soundEnabled, forKey: Keys.soundEnabled) }
    }
    
    @Published var hapticsEnabled: Bool {
        didSet { userDefaults.set(hapticsEnabled, forKey: Keys.hapticsEnabled) }
    }
    
    // MARK: - Computed Properties
    var totalGamesPlayed: Int {
        ticTacToeGamesPlayed + memoryGamesPlayed + dictionaryGamesPlayed + hangmanGamesPlayed
    }
    
    var ticTacToeWinRate: Double {
        guard ticTacToeGamesPlayed > 0 else { return 0 }
        return Double(ticTacToeXWins + ticTacToeOWins) / Double(ticTacToeGamesPlayed) * 100
    }
    
    var memoryWinRate: Double {
        guard memoryGamesPlayed > 0 else { return 0 }
        return Double(memoryGamesWon) / Double(memoryGamesPlayed) * 100
    }
    
    var hangmanWinRate: Double {
        guard hangmanGamesPlayed > 0 else { return 0 }
        return Double(hangmanGamesWon) / Double(hangmanGamesPlayed) * 100
    }
    
    // MARK: - Initialization
    private init() {
        // Load Tic-Tac-Toe stats
        self.ticTacToeGamesPlayed = userDefaults.integer(forKey: Keys.ticTacToeGamesPlayed)
        self.ticTacToeXWins = userDefaults.integer(forKey: Keys.ticTacToeXWins)
        self.ticTacToeOWins = userDefaults.integer(forKey: Keys.ticTacToeOWins)
        self.ticTacToeDraws = userDefaults.integer(forKey: Keys.ticTacToeDraws)
        
        // Load Memory game stats
        self.memoryGamesPlayed = userDefaults.integer(forKey: Keys.memoryGamesPlayed)
        self.memoryGamesWon = userDefaults.integer(forKey: Keys.memoryGamesWon)
        self.memoryHighScore = userDefaults.integer(forKey: Keys.memoryHighScore)
        self.memoryPreferredTheme = userDefaults.string(forKey: Keys.memoryPreferredTheme) ?? "Animals"
        
        // Load Dictionary game stats
        self.dictionaryGamesPlayed = userDefaults.integer(forKey: Keys.dictionaryGamesPlayed)
        self.dictionaryHighScore = userDefaults.integer(forKey: Keys.dictionaryHighScore)
        self.dictionaryPreferredDifficulty = userDefaults.string(forKey: Keys.dictionaryPreferredDifficulty) ?? "Medium"
        
        // Load Hangman stats
        self.hangmanGamesPlayed = userDefaults.integer(forKey: Keys.hangmanGamesPlayed)
        self.hangmanGamesWon = userDefaults.integer(forKey: Keys.hangmanGamesWon)
        self.hangmanGamesLost = userDefaults.integer(forKey: Keys.hangmanGamesLost)
        self.hangmanHighScore = userDefaults.integer(forKey: Keys.hangmanHighScore)
        self.hangmanPreferredCategory = userDefaults.string(forKey: Keys.hangmanPreferredCategory) ?? "Animals"
        
        // Load user preferences
        self.soundEnabled = userDefaults.object(forKey: Keys.soundEnabled) as? Bool ?? true
        self.hapticsEnabled = userDefaults.object(forKey: Keys.hapticsEnabled) as? Bool ?? true
    }
    
    // MARK: - Public Methods
    
    /// Record a Tic-Tac-Toe game result
    func recordTicTacToeGame(winner: Player?, isDraw: Bool) {
        ticTacToeGamesPlayed += 1
        
        if isDraw {
            ticTacToeDraws += 1
        } else if let winner = winner {
            if winner == .x {
                ticTacToeXWins += 1
            } else {
                ticTacToeOWins += 1
            }
        }
        
        saveToUserDefaults()
    }
    
    /// Record a Memory game result
    func recordMemoryGame(score: Int, won: Bool) {
        memoryGamesPlayed += 1
        
        if won {
            memoryGamesWon += 1
        }
        
        if score > memoryHighScore {
            memoryHighScore = score
        }
        
        saveToUserDefaults()
    }
    
    /// Record a Dictionary game score
    func recordDictionaryGame(score: Int) {
        dictionaryGamesPlayed += 1
        
        if score > dictionaryHighScore {
            dictionaryHighScore = score
        }
        
        saveToUserDefaults()
    }
    
    /// Record a Hangman game result
    func recordHangmanGame(score: Int, won: Bool) {
        hangmanGamesPlayed += 1
        
        if won {
            hangmanGamesWon += 1
        } else {
            hangmanGamesLost += 1
        }
        
        if score > hangmanHighScore {
            hangmanHighScore = score
        }
        
        saveToUserDefaults()
    }
    
    /// Batch save all statistics to UserDefaults
    private func saveToUserDefaults() {
        // Tic-Tac-Toe
        userDefaults.set(ticTacToeGamesPlayed, forKey: Keys.ticTacToeGamesPlayed)
        userDefaults.set(ticTacToeXWins, forKey: Keys.ticTacToeXWins)
        userDefaults.set(ticTacToeOWins, forKey: Keys.ticTacToeOWins)
        userDefaults.set(ticTacToeDraws, forKey: Keys.ticTacToeDraws)
        
        // Memory Game
        userDefaults.set(memoryGamesPlayed, forKey: Keys.memoryGamesPlayed)
        userDefaults.set(memoryGamesWon, forKey: Keys.memoryGamesWon)
        userDefaults.set(memoryHighScore, forKey: Keys.memoryHighScore)
        userDefaults.set(memoryPreferredTheme, forKey: Keys.memoryPreferredTheme)
        
        // Dictionary Game
        userDefaults.set(dictionaryGamesPlayed, forKey: Keys.dictionaryGamesPlayed)
        userDefaults.set(dictionaryHighScore, forKey: Keys.dictionaryHighScore)
        userDefaults.set(dictionaryPreferredDifficulty, forKey: Keys.dictionaryPreferredDifficulty)
        
        // Hangman
        userDefaults.set(hangmanGamesPlayed, forKey: Keys.hangmanGamesPlayed)
        userDefaults.set(hangmanGamesWon, forKey: Keys.hangmanGamesWon)
        userDefaults.set(hangmanGamesLost, forKey: Keys.hangmanGamesLost)
        userDefaults.set(hangmanHighScore, forKey: Keys.hangmanHighScore)
        userDefaults.set(hangmanPreferredCategory, forKey: Keys.hangmanPreferredCategory)
    }
    
    /// Reset all statistics
    func resetAllStatistics() {
        // Reset Tic-Tac-Toe
        ticTacToeGamesPlayed = 0
        ticTacToeXWins = 0
        ticTacToeOWins = 0
        ticTacToeDraws = 0
        
        // Reset Memory
        memoryGamesPlayed = 0
        memoryGamesWon = 0
        memoryHighScore = 0
        
        // Reset Dictionary
        dictionaryGamesPlayed = 0
        dictionaryHighScore = 0
        
        // Reset Hangman
        hangmanGamesPlayed = 0
        hangmanGamesWon = 0
        hangmanGamesLost = 0
        hangmanHighScore = 0
        
        saveToUserDefaults()
    }
}
