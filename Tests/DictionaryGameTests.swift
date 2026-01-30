import XCTest
@testable import GamesApp

@MainActor
final class DictionaryGameTests: XCTestCase {
    var gameState: DictionaryGameState!
    
    nonisolated override func setUp() {
        super.setUp()
    }
    
    nonisolated override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testDictionaryGameStateInitialization() {
        gameState = DictionaryGameState(startImmediately: false)
        gameState.loadLocalQuestion()
        XCTAssertEqual(gameState.score, 0)
        XCTAssertFalse(gameState.isGameOver)
        XCTAssertEqual(gameState.options.count, 4, "Should have 4 options")
    }
    
    // MARK: - Difficulty Tests
    
    func testSetDifficulty() {
        gameState = DictionaryGameState(startImmediately: false)
        gameState.loadLocalQuestion()
        
        gameState.setDifficulty(.medium)
        XCTAssertEqual(gameState.difficulty, .medium)
        
        gameState.setDifficulty(.hard)
        XCTAssertEqual(gameState.difficulty, .hard)
    }
    
    // MARK: - Question Generation Tests
    
    func testOptionsContainCorrectAnswer() {
        gameState = DictionaryGameState(startImmediately: false)
        gameState.loadLocalQuestion()
        
        if let currentWord = gameState.currentWord {
            XCTAssertTrue(gameState.options.contains(currentWord.definition),
                         "Options should contain correct definition")
        } else {
            XCTFail("Game should have a current word after initialization")
        }
    }
    
    func testOptionsAreUnique() {
        gameState = DictionaryGameState(startImmediately: false)
        gameState.loadLocalQuestion()
        
        let uniqueOptions = Set(gameState.options)
        XCTAssertEqual(gameState.options.count, uniqueOptions.count, "All options should be unique")
    }
    
    // MARK: - Answer Validation Tests
    
    func testCheckAnswerCorrect() {
        gameState = DictionaryGameState(startImmediately: false)
        gameState.loadLocalQuestion()
        
        guard let correctAnswer = gameState.currentWord?.definition else {
            XCTFail("No current word available")
            return
        }
        
        let initialScore = gameState.score
        gameState.checkAnswer(correctAnswer)
        
        XCTAssertEqual(gameState.selectedOption, correctAnswer)
        XCTAssertEqual(gameState.score, initialScore + 1, "Score should increase by 1 for correct answer")
    }
    
    func testCheckAnswerIncorrect() {
        gameState = DictionaryGameState(startImmediately: false)
        gameState.loadLocalQuestion()
        
        guard let correctAnswer = gameState.currentWord?.definition else {
            XCTFail("No current word available")
            return
        }
        
        // Find a wrong answer
        let wrongAnswer = gameState.options.first(where: { $0 != correctAnswer })!
        
        let initialScore = gameState.score
        gameState.checkAnswer(wrongAnswer)
        
        XCTAssertEqual(gameState.selectedOption, wrongAnswer)
        XCTAssertEqual(gameState.score, initialScore, "Score should not change for incorrect answer")
    }
    
    // MARK: - Score Calculation Tests
    
    func testScoreIncreasesWithCorrectAnswers() {
        gameState = DictionaryGameState(startImmediately: false)
        gameState.loadLocalQuestion()
        
        guard let correctAnswer = gameState.currentWord?.definition else {
            XCTFail("No current word available")
            return
        }
        
        XCTAssertEqual(gameState.score, 0)
        
        gameState.checkAnswer(correctAnswer)
        XCTAssertEqual(gameState.score, 1)
        
        gameState.nextQuestion()
        gameState.loadLocalQuestion()
        
        if let nextCorrectAnswer = gameState.currentWord?.definition {
            gameState.checkAnswer(nextCorrectAnswer)
            XCTAssertEqual(gameState.score, 2)
        }
    }
    
    func testScoreDoesNotDecreaseWithIncorrectAnswers() {
        gameState = DictionaryGameState(startImmediately: false)
        gameState.loadLocalQuestion()
        
        guard let correctAnswer = gameState.currentWord?.definition else {
            XCTFail("No current word available")
            return
        }
        
        gameState.checkAnswer(correctAnswer)
        XCTAssertEqual(gameState.score, 1)
        
        gameState.nextQuestion()
        gameState.loadLocalQuestion()
        
        if let wrongAnswer = gameState.options.first(where: { $0 != gameState.currentWord?.definition }) {
            gameState.checkAnswer(wrongAnswer)
            XCTAssertEqual(gameState.score, 1, "Score should not decrease")
        }
    }
    
    // MARK: - Game Flow Tests
    
    func testNextQuestionResetsSelection() {
        gameState = DictionaryGameState(startImmediately: false)
        gameState.loadLocalQuestion()
        
        if let correctAnswer = gameState.currentWord?.definition {
            gameState.checkAnswer(correctAnswer)
        }
        
        XCTAssertNotNil(gameState.selectedOption)
        
        gameState.nextQuestion()
        
        XCTAssertNil(gameState.selectedOption, "Selected option should be cleared")
    }
    
    func testMultipleCorrectAnswersInRow() {
        gameState = DictionaryGameState(startImmediately: false)
        gameState.loadLocalQuestion()
        
        for i in 0..<3 {
            if let correctAnswer = gameState.currentWord?.definition {
                gameState.checkAnswer(correctAnswer)
                XCTAssertEqual(gameState.score, i + 1)
                
                gameState.nextQuestion()
                gameState.loadLocalQuestion()
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testCheckAnswerTwice() {
        gameState = DictionaryGameState(startImmediately: false)
        gameState.loadLocalQuestion()
        
        guard let correctAnswer = gameState.currentWord?.definition else {
            XCTFail("No current word available")
            return
        }
        
        gameState.checkAnswer(correctAnswer)
        let scoreAfterFirst = gameState.score
        XCTAssertEqual(gameState.selectedOption, correctAnswer, "First answer should be recorded")
        
        // Try to answer again with a different option
        let wrongAnswer = gameState.options.first(where: { $0 != correctAnswer })!
        gameState.checkAnswer(wrongAnswer)
        
        // Score should not change (already answered)
        XCTAssertEqual(gameState.score, scoreAfterFirst, "Should not be able to answer twice")
        // Selection should still be the first answer since we can't change it
        XCTAssertNotNil(gameState.selectedOption, "Selected option should still exist")
    }
    
    // MARK: - Word Model Tests
    
    func testWordHasRequiredProperties() {
        gameState = DictionaryGameState(startImmediately: false)
        gameState.loadLocalQuestion()
        
        if let word = gameState.currentWord {
            XCTAssertFalse(word.term.isEmpty, "Word term should not be empty")
            XCTAssertFalse(word.definition.isEmpty, "Word definition should not be empty")
        } else {
            XCTFail("Game should have a current word")
        }
    }
}
