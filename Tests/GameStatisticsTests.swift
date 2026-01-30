import XCTest
@testable import GamesApp

@MainActor
final class GameStatisticsTests: XCTestCase {
    var stats: GameStatistics!
    
    nonisolated override func setUp() {
        super.setUp()
    }
    
    nonisolated override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        XCTAssertEqual(stats.totalGamesPlayed, 0)
        XCTAssertEqual(stats.ticTacToeGamesPlayed, 0)
        XCTAssertEqual(stats.memoryGamesPlayed, 0)
        XCTAssertEqual(stats.dictionaryGamesPlayed, 0)
        XCTAssertEqual(stats.hangmanGamesPlayed, 0)
    }
    
    // MARK: - Tic-Tac-Toe Statistics Tests
    
    func testRecordTicTacToeXWin() {
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        stats.recordTicTacToeGame(winner: .x, isDraw: false)
        
        XCTAssertEqual(stats.ticTacToeGamesPlayed, 1)
        XCTAssertEqual(stats.ticTacToeXWins, 1)
        XCTAssertEqual(stats.ticTacToeOWins, 0)
        XCTAssertEqual(stats.ticTacToeDraws, 0)
        XCTAssertEqual(stats.totalGamesPlayed, 1)
    }
    
    func testRecordTicTacToeOWin() {
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        stats.recordTicTacToeGame(winner: .o, isDraw: false)
        
        XCTAssertEqual(stats.ticTacToeGamesPlayed, 1)
        XCTAssertEqual(stats.ticTacToeXWins, 0)
        XCTAssertEqual(stats.ticTacToeOWins, 1)
        XCTAssertEqual(stats.ticTacToeDraws, 0)
    }
    
    func testRecordTicTacToeDraw() {
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        stats.recordTicTacToeGame(winner: nil, isDraw: true)
        
        XCTAssertEqual(stats.ticTacToeGamesPlayed, 1)
        XCTAssertEqual(stats.ticTacToeXWins, 0)
        XCTAssertEqual(stats.ticTacToeOWins, 0)
        XCTAssertEqual(stats.ticTacToeDraws, 1)
    }
    
    func testTicTacToeWinRate() {
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        stats.recordTicTacToeGame(winner: .x, isDraw: false)
        stats.recordTicTacToeGame(winner: .o, isDraw: false)
        stats.recordTicTacToeGame(winner: nil, isDraw: true)
        stats.recordTicTacToeGame(winner: .x, isDraw: false)
        
        // 3 wins (2 X, 1 O) out of 4 games = 75%
        XCTAssertEqual(stats.ticTacToeWinRate, 75.0, accuracy: 0.1)
    }
    
    func testTicTacToeWinRateWithNoGames() {
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        XCTAssertEqual(stats.ticTacToeWinRate, 0.0)
    }
    
    // MARK: - Memory Game Statistics Tests
    
    func testRecordMemoryGameWin() {
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        stats.recordMemoryGame(score: 100, won: true)
        
        XCTAssertEqual(stats.memoryGamesPlayed, 1)
        XCTAssertEqual(stats.memoryGamesWon, 1)
        XCTAssertEqual(stats.memoryHighScore, 100)
        XCTAssertEqual(stats.totalGamesPlayed, 1)
    }
    
    func testRecordMemoryGameLoss() {
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        stats.recordMemoryGame(score: 50, won: false)
        
        XCTAssertEqual(stats.memoryGamesPlayed, 1)
        XCTAssertEqual(stats.memoryGamesWon, 0)
        XCTAssertEqual(stats.memoryHighScore, 50)
    }
    
    func testMemoryHighScoreTracking() {
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        stats.recordMemoryGame(score: 50, won: true)
        XCTAssertEqual(stats.memoryHighScore, 50)
        
        stats.recordMemoryGame(score: 100, won: true)
        XCTAssertEqual(stats.memoryHighScore, 100)
        
        stats.recordMemoryGame(score: 75, won: true)
        XCTAssertEqual(stats.memoryHighScore, 100, "High score should not decrease")
    }
    
    func testMemoryWinRate() {
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        stats.recordMemoryGame(score: 100, won: true)
        stats.recordMemoryGame(score: 50, won: false)
        stats.recordMemoryGame(score: 75, won: true)
        stats.recordMemoryGame(score: 25, won: false)
        
        // 2 wins out of 4 games = 50%
        XCTAssertEqual(stats.memoryWinRate, 50.0, accuracy: 0.1)
    }
    
    func testMemoryWinRateWithNoGames() {
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        XCTAssertEqual(stats.memoryWinRate, 0.0)
    }
    
    // MARK: - Dictionary Game Statistics Tests
    
    func testRecordDictionaryGame() {
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        stats.recordDictionaryGame(score: 50)
        
        XCTAssertEqual(stats.dictionaryGamesPlayed, 1)
        XCTAssertEqual(stats.dictionaryHighScore, 50)
        XCTAssertEqual(stats.totalGamesPlayed, 1)
    }
    
    func testDictionaryHighScoreTracking() {
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        stats.recordDictionaryGame(score: 30)
        XCTAssertEqual(stats.dictionaryHighScore, 30)
        
        stats.recordDictionaryGame(score: 50)
        XCTAssertEqual(stats.dictionaryHighScore, 50)
        
        stats.recordDictionaryGame(score: 40)
        XCTAssertEqual(stats.dictionaryHighScore, 50, "High score should not decrease")
    }
    
    // MARK: - Hangman Statistics Tests
    
    func testRecordHangmanWin() {
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        stats.recordHangmanGame(score: 100, won: true)
        
        XCTAssertEqual(stats.hangmanGamesPlayed, 1)
        XCTAssertEqual(stats.hangmanGamesWon, 1)
        XCTAssertEqual(stats.hangmanGamesLost, 0)
        XCTAssertEqual(stats.hangmanHighScore, 100)
        XCTAssertEqual(stats.totalGamesPlayed, 1)
    }
    
    func testRecordHangmanLoss() {
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        stats.recordHangmanGame(score: 50, won: false)
        
        XCTAssertEqual(stats.hangmanGamesPlayed, 1)
        XCTAssertEqual(stats.hangmanGamesWon, 0)
        XCTAssertEqual(stats.hangmanGamesLost, 1)
        XCTAssertEqual(stats.hangmanHighScore, 50)
    }
    
    func testHangmanWinRate() {
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        stats.recordHangmanGame(score: 100, won: true)
        stats.recordHangmanGame(score: 50, won: false)
        stats.recordHangmanGame(score: 75, won: true)
        
        // 2 wins out of 3 games = 66.67%
        XCTAssertEqual(stats.hangmanWinRate, 66.67, accuracy: 0.1)
    }
    
    func testHangmanWinRateWithNoGames() {
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        XCTAssertEqual(stats.hangmanWinRate, 0.0)
    }
    
    func testHangmanHighScoreTracking() {
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        stats.recordHangmanGame(score: 50, won: true)
        XCTAssertEqual(stats.hangmanHighScore, 50)
        
        stats.recordHangmanGame(score: 100, won: true)
        XCTAssertEqual(stats.hangmanHighScore, 100)
        
        stats.recordHangmanGame(score: 75, won: true)
        XCTAssertEqual(stats.hangmanHighScore, 100, "High score should not decrease")
    }
    
    // MARK: - Total Statistics Tests
    
    func testTotalGamesPlayed() {
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        stats.recordTicTacToeGame(winner: .x, isDraw: false)
        stats.recordMemoryGame(score: 100, won: true)
        stats.recordDictionaryGame(score: 50)
        stats.recordHangmanGame(score: 75, won: true)
        
        XCTAssertEqual(stats.totalGamesPlayed, 4)
    }
    
    // MARK: - Reset Tests
    
    func testResetAllStatistics() {
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        // Record some games
        stats.recordTicTacToeGame(winner: .x, isDraw: false)
        stats.recordMemoryGame(score: 100, won: true)
        stats.recordDictionaryGame(score: 50)
        stats.recordHangmanGame(score: 75, won: true)
        
        XCTAssertEqual(stats.totalGamesPlayed, 4)
        
        // Reset
        stats.resetAllStatistics()
        
        // Verify all stats are reset
        XCTAssertEqual(stats.totalGamesPlayed, 0)
        XCTAssertEqual(stats.ticTacToeGamesPlayed, 0)
        XCTAssertEqual(stats.memoryGamesPlayed, 0)
        XCTAssertEqual(stats.dictionaryGamesPlayed, 0)
        XCTAssertEqual(stats.hangmanGamesPlayed, 0)
        XCTAssertEqual(stats.memoryHighScore, 0)
        XCTAssertEqual(stats.dictionaryHighScore, 0)
        XCTAssertEqual(stats.hangmanHighScore, 0)
    }
    
    // MARK: - Edge Cases
    
    func testNegativeScoresHandled() {
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        stats.recordMemoryGame(score: -10, won: false)
        XCTAssertEqual(stats.memoryHighScore, 0, "Negative scores should be treated as 0")
    }
    
    func testMultipleGamesInSequence() {
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        // Play multiple games
        for i in 0..<10 {
            stats.recordTicTacToeGame(winner: i % 3 == 0 ? .x : (i % 3 == 1 ? .o : nil), isDraw: i % 3 == 2)
        }
        
        XCTAssertEqual(stats.ticTacToeGamesPlayed, 10)
        XCTAssertGreaterThan(stats.ticTacToeWinRate, 0)
    }
    
    // MARK: - Settings Tests
    
    func testSoundEnabledToggle() {
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        XCTAssertTrue(stats.soundEnabled, "Sound should be enabled by default")
        
        stats.soundEnabled = false
        XCTAssertFalse(stats.soundEnabled)
        
        stats.soundEnabled = true
        XCTAssertTrue(stats.soundEnabled)
    }
    
    func testHapticsEnabledToggle() {
        stats = GameStatistics.shared
        stats.resetAllStatistics()
        
        XCTAssertTrue(stats.hapticsEnabled, "Haptics should be enabled by default")
        
        stats.hapticsEnabled = false
        XCTAssertFalse(stats.hapticsEnabled)
        
        stats.hapticsEnabled = true
        XCTAssertTrue(stats.hapticsEnabled)
    }
}
