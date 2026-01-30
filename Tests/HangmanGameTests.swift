import XCTest
@testable import GamesApp

@MainActor
final class HangmanGameTests: XCTestCase {
    func testInitialization() {
        let state = HangmanGameState()
        
        XCTAssertFalse(state.currentWord.isEmpty)
        XCTAssertTrue(state.guessedLetters.isEmpty)
        XCTAssertEqual(state.wrongGuesses, 0)
        XCTAssertEqual(state.score, 0)
        XCTAssertFalse(state.isGameOver)
        XCTAssertFalse(state.hasWon)
    }
    
    func testCorrectGuess() {
        let state = HangmanGameState()
        let word = state.currentWord
        let firstLetter = word.first!
        
        state.guessLetter(firstLetter)
        
        XCTAssertTrue(state.guessedLetters.contains(firstLetter))
        XCTAssertEqual(state.wrongGuesses, 0) // Should not increment wrong guesses
    }
    
    func testWrongGuess() {
        let state = HangmanGameState()
        let word = state.currentWord
        
        // Find a letter not in the word
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let wrongLetter = alphabet.first { letter in
            !word.contains(letter)
        }!
        
        state.guessLetter(wrongLetter)
        
        XCTAssertTrue(state.guessedLetters.contains(wrongLetter))
        XCTAssertEqual(state.wrongGuesses, 1)
    }
    
    func testWinCondition() {
        let state = HangmanGameState()
        let word = state.currentWord
        
        // Guess all letters in the word
        let uniqueLetters = Set(word)
        for letter in uniqueLetters {
            state.guessLetter(letter)
        }
        
        XCTAssertTrue(state.hasWon)
        XCTAssertTrue(state.isGameOver)
        XCTAssertEqual(state.gamesWon, 1)
        XCTAssertEqual(state.score, 10)
    }
    
    func testLoseCondition() {
        let state = HangmanGameState()
        let word = state.currentWord
        
        // Find 8 wrong letters
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        var wrongCount = 0
        
        for letter in alphabet {
            if !word.contains(letter) && wrongCount < 8 {
                state.guessLetter(letter)
                wrongCount += 1
            }
        }
        
        XCTAssertFalse(state.hasWon)
        XCTAssertTrue(state.isGameOver)
        XCTAssertEqual(state.gamesLost, 1)
        XCTAssertEqual(state.wrongGuesses, 8)
    }
    
    func testDisplayWord() {
        let state = HangmanGameState()
        state.currentWord = "CAT"
        
        // No guesses yet
        XCTAssertEqual(state.getDisplayWord(), "_ _ _")
        
        // Guess 'C'
        state.guessLetter("C")
        XCTAssertEqual(state.getDisplayWord(), "C _ _")
        
        // Guess 'T'
        state.guessLetter("T")
        XCTAssertEqual(state.getDisplayWord(), "C _ T")
        
        // Guess 'A'
        state.guessLetter("A")
        XCTAssertEqual(state.getDisplayWord(), "C A T")
    }
    
    func testCategoryChange() {
        let state = HangmanGameState()
        let initialWord = state.currentWord
        
        state.setCategory(.food)
        
        XCTAssertEqual(state.selectedCategory, .food)
        // Word should change when category changes
        XCTAssertNotEqual(state.currentWord, initialWord)
        // Stats should reset
        XCTAssertTrue(state.guessedLetters.isEmpty)
        XCTAssertEqual(state.wrongGuesses, 0)
    }
}
