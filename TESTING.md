# 🧪 Testing Guide

Complete guide to testing in the iOS Game App project.

## Table of Contents

1. [Overview](#overview)
2. [Running Tests](#running-tests)
3. [Test Structure](#test-structure)
4. [Writing Tests](#writing-tests)
5. [Testing Patterns](#testing-patterns)
6. [CI/CD Pipeline](#cicd-pipeline)
7. [Coverage Goals](#coverage-goals)
8. [Troubleshooting](#troubleshooting)

---

## Overview

This project uses **XCTest** for unit testing. We test game logic, state management, and business rules, but not UI (which would require UI testing framework).

### What We Test

✅ **Game Logic**
- Move validation
- Win/loss/draw detection
- Scoring algorithms
- State transitions
- AI opponent strategies

✅ **Business Rules**
- Turn switching
- Game over conditions
- Statistics recording
- Data persistence logic
- Async task management

### What We DON'T Test

❌ **UI/Views** - SwiftUI views (requires UITest framework)  
❌ **Managers** - Singletons with side effects (sound, haptics)  
❌ **APIs** - External network calls (would need mocking)

---

## Running Tests

### Option 1: Xcode (Recommended)

```bash
# Open project
open TicTacToe/TicTacToe.xcodeproj

# Run all tests: Cmd+U
# Or: Product → Test

# Run specific test class:
# Click diamond icon next to class name

# Run single test:
# Click diamond icon next to test method
```

### Option 2: Command Line (Fast)

```bash
cd TicTacToe
swift test

# Run specific test
swift test --filter TicTacToeGameStateTests

# Parallel execution (faster)
swift test --parallel

# Verbose output
swift test --verbose
```

### Option 3: Xcodebuild (CI/CD)

```bash
cd TicTacToe
xcodebuild test \
  -project TicTacToe.xcodeproj \
  -scheme TicTacToe \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

### Expected Output

```
Test Suite 'All tests' started
Test Suite 'GameStatisticsTests' passed
	 Executed 24 tests, with 0 failures (0 unexpected) in 0.020 seconds
Test Suite 'TicTacToeGameStateTests' passed
	 Executed 38 tests, with 0 failures (0 unexpected) in 69.298 seconds
Test Suite 'MemoryGameStateTests' passed
	 Executed 14 tests, with 0 failures (0 unexpected) in 5.058 seconds
Test Suite 'DictionaryGameTests' passed
	 Executed 12 tests, with 0 failures (0 unexpected) in 0.006 seconds
Test Suite 'HangmanGameTests' passed
	 Executed 7 tests, with 0 failures (0 unexpected) in 0.003 seconds
Test Suite 'All tests' passed
	 Executed 95 tests, with 0 failures (0 unexpected) in 74.386 seconds
```

---

## Test Structure

### File Organization

```
Tests/
├── GameStatisticsTests.swift        # 24 tests
├── TicTacToeGameStateTests.swift    # 38 tests (includes 22 AI tests)
├── MemoryGameStateTests.swift       # 14 tests
├── DictionaryGameTests.swift        # 12 tests
└── HangmanGameTests.swift           # 7 tests

Total: 95 tests
```

### Anatomy of a Test File

```swift
import XCTest
@testable import GamesApp  // Access to internal types

@MainActor  // REQUIRED: GameState classes are @MainActor
final class TicTacToeGameStateTests: XCTestCase {
    
    // MARK: - Properties
    var gameState: TicTacToeGameState!
    
    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        gameState = TicTacToeGameState()
    }
    
    override func tearDown() {
        gameState = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testInitialization() {
        XCTAssertEqual(gameState.board.count, 9)
        XCTAssertEqual(gameState.currentPlayer, .x)
        XCTAssertNil(gameState.winner)
        XCTAssertFalse(gameState.isDraw)
    }
    
    func testValidMove() {
        gameState.makeMove(at: 0)
        XCTAssertEqual(gameState.board[0], .x)
        XCTAssertEqual(gameState.currentPlayer, .o)
    }
    
    // ... more tests
}
```

### Key Components

1. **`@testable import GamesApp`**: Access internal types
2. **`@MainActor`**: Required for GameState access
3. **`setUp()`**: Initialize fresh state before each test
4. **`tearDown()`**: Clean up after each test
5. **`func test...()`**: Test methods (must start with "test")

---

## Writing Tests

### Basic Test Template

```swift
func testFeatureName() {
    // Arrange: Set up initial state
    let input = "test"
    
    // Act: Perform the action
    gameState.performAction(input)
    
    // Assert: Verify the result
    XCTAssertEqual(gameState.result, expectedValue)
}
```

### XCTest Assertions

| Assertion | Use Case | Example |
|-----------|----------|---------|
| `XCTAssertTrue(condition)` | Check boolean is true | `XCTAssertTrue(gameState.isGameOver)` |
| `XCTAssertFalse(condition)` | Check boolean is false | `XCTAssertFalse(gameState.isDraw)` |
| `XCTAssertEqual(a, b)` | Check equality | `XCTAssertEqual(gameState.score, 10)` |
| `XCTAssertNotEqual(a, b)` | Check inequality | `XCTAssertNotEqual(player, nil)` |
| `XCTAssertNil(value)` | Check value is nil | `XCTAssertNil(gameState.winner)` |
| `XCTAssertNotNil(value)` | Check value is not nil | `XCTAssertNotNil(gameState.currentWord)` |
| `XCTAssertGreaterThan(a, b)` | Check a > b | `XCTAssertGreaterThan(score, 0)` |
| `XCTAssertThrowsError(expr)` | Check throws error | `XCTAssertThrowsError(try api.fetch())` |

### Example: Testing Tic-Tac-Toe Win

```swift
func testHorizontalWinTopRow() {
    // Arrange: Set up board state
    // X X X
    // O O _
    // _ _ _
    
    // Act: Make winning moves
    gameState.makeMove(at: 0)  // X at position 0
    gameState.makeMove(at: 3)  // O at position 3
    gameState.makeMove(at: 1)  // X at position 1
    gameState.makeMove(at: 4)  // O at position 4
    gameState.makeMove(at: 2)  // X at position 2 (WIN!)
    
    // Assert: X should win
    XCTAssertEqual(gameState.winner, .x)
    XCTAssertTrue(gameState.winner != nil)
}
```

### Example: Testing Memory Game Match

```swift
func testMatchingPair() {
    // Arrange: Get two cards with same content
    let firstCard = gameState.cards[0]
    let secondCard = gameState.cards.first { $0.content == firstCard.content && $0.id != firstCard.id }!
    
    // Act: Choose both cards
    gameState.choose(firstCard)
    gameState.choose(secondCard)
    
    // Assert: Both should be matched
    let updatedFirst = gameState.cards.first { $0.id == firstCard.id }!
    let updatedSecond = gameState.cards.first { $0.id == secondCard.id }!
    
    XCTAssertTrue(updatedFirst.isMatched)
    XCTAssertTrue(updatedSecond.isMatched)
    XCTAssertEqual(gameState.score, 2)  // +2 for match
}
```

### Example: Testing Hangman Letter Guess

```swift
func testCorrectGuess() {
    // Arrange: Set known word
    gameState.currentWord = "CAT"
    
    // Act: Guess a correct letter
    gameState.guessLetter("C")
    
    // Assert: Letter should be in guessed set, no wrong guesses
    XCTAssertTrue(gameState.guessedLetters.contains("C"))
    XCTAssertEqual(gameState.wrongGuesses, 0)
    XCTAssertEqual(gameState.displayWord, "C _ _ ")
}

func testWrongGuess() {
    // Arrange: Set known word
    gameState.currentWord = "CAT"
    
    // Act: Guess a wrong letter
    gameState.guessLetter("Z")
    
    // Assert: Wrong guess count should increase
    XCTAssertTrue(gameState.guessedLetters.contains("Z"))
    XCTAssertEqual(gameState.wrongGuesses, 1)
}
```

---

## Testing Patterns

### Pattern 1: Test Initialization

Always test that objects start in correct state:

```swift
func testInitialization() {
    XCTAssertEqual(gameState.score, 0)
    XCTAssertEqual(gameState.gamesPlayed, 0)
    XCTAssertFalse(gameState.isGameOver)
    XCTAssertNotNil(gameState.currentWord)
}
```

### Pattern 2: Test State Transitions

Verify state changes correctly:

```swift
func testTurnSwitching() {
    // Start with X
    XCTAssertEqual(gameState.currentPlayer, .x)
    
    // Make move
    gameState.makeMove(at: 0)
    
    // Should switch to O
    XCTAssertEqual(gameState.currentPlayer, .o)
    
    // Make another move
    gameState.makeMove(at: 1)
    
    // Should switch back to X
    XCTAssertEqual(gameState.currentPlayer, .x)
}
```

### Pattern 3: Test Edge Cases

Test boundary conditions:

```swift
func testCannotMoveOnOccupiedCell() {
    // First move
    gameState.makeMove(at: 0)
    XCTAssertEqual(gameState.board[0], .x)
    
    // Try to move on same cell
    gameState.makeMove(at: 0)
    
    // Should still be X, not O
    XCTAssertEqual(gameState.board[0], .x)
    XCTAssertEqual(gameState.currentPlayer, .o)  // Turn shouldn't switch
}

func testCannotMoveAfterGameOver() {
    // Simulate game over
    gameState.winner = .x
    
    // Try to make move
    gameState.makeMove(at: 4)
    
    // Board should be unchanged
    XCTAssertNil(gameState.board[4])
}
```

### Pattern 4: Test All Win Conditions

For games with multiple win patterns:

```swift
func testHorizontalWinTopRow() { /* ... */ }
func testHorizontalWinMiddleRow() { /* ... */ }
func testHorizontalWinBottomRow() { /* ... */ }
func testVerticalWinLeftColumn() { /* ... */ }
func testVerticalWinMiddleColumn() { /* ... */ }
func testVerticalWinRightColumn() { /* ... */ }
func testDiagonalWinTopLeftToBottomRight() { /* ... */ }
func testDiagonalWinTopRightToBottomLeft() { /* ... */ }
```

### Pattern 5: Test Async Operations

For features with delays or async tasks:

```swift
@MainActor
func testMemoryGameMismatchDelay() async throws {
    // Arrange: Get two non-matching cards
    let firstCard = gameState.cards[0]
    let secondCard = gameState.cards.first { $0.content != firstCard.content }!
    
    // Act: Choose both cards
    gameState.choose(firstCard)
    gameState.choose(secondCard)
    
    // Assert: Cards should stay face up initially
    XCTAssertTrue(gameState.isProcessingMismatch)
    
    // Wait for mismatch delay (1.5 seconds)
    try await Task.sleep(for: .seconds(1.6))
    
    // Assert: Cards should be flipped back
    let updatedFirst = gameState.cards.first { $0.id == firstCard.id }!
    let updatedSecond = gameState.cards.first { $0.id == secondCard.id }!
    XCTAssertFalse(updatedFirst.isFaceUp)
    XCTAssertFalse(updatedSecond.isFaceUp)
    XCTAssertFalse(gameState.isProcessingMismatch)
}
```

**Key Points:**
- Mark test function with `async throws` for async testing
- Use `try await Task.sleep(for:)` to wait for delays
- Wait slightly longer than actual delay (1.6s for 1.5s delay)
- All GameState access must be on `@MainActor`

### Pattern 6: Test AI Strategies

Testing AI opponent requires multiple game simulations:

```swift
@MainActor
func testHardAINeverLoses() async throws {
    let state = TicTacToeGameState()
    state.changeGameMode(.vsAI)
    state.changeAIDifficulty(.hard)
    
    // Play 10 games with random player moves
    for gameNumber in 1...10 {
        state.resetGame()
        
        var moveCount = 0
        while (state.winner == nil && !state.isDraw) && moveCount < 20 {
            // Player X makes random valid move
            if state.currentPlayer == .x && !state.isAIThinking {
                let available = state.board.enumerated()
                    .filter { $0.element == nil }
                    .map { $0.offset }
                if let move = available.randomElement() {
                    state.makeMove(at: move)
                }
            }
            
            // Wait for AI to move
            try await Task.sleep(for: .seconds(1.5))
            moveCount += 1
        }
        
        // AI should never lose (only win or draw)
        XCTAssertNotEqual(state.winner, .x, "Hard AI should never lose (Game \(gameNumber))")
    }
}
```

**Key Points:**
- Test AI across multiple games (10+) for consistency
- Use `Task.sleep` to wait for AI thinking delays
- Check AI never loses (only wins or draws)
- Test different difficulty levels separately

### Pattern 7: Mock GameStatistics (When Needed)

For testing without side effects:

```swift
func testGameRecordsStatistics() {
    // Note: GameStatistics has side effects (writes to UserDefaults)
    // For now, we test that methods are called, not the persistence
    
    let initialPlayed = GameStatistics.shared.ticTacToeGamesPlayed
    
    // Simulate game end
    gameState.makeMove(at: 0)
    // ... complete game ...
    
    // Verify statistics updated
    XCTAssertEqual(
        GameStatistics.shared.ticTacToeGamesPlayed,
        initialPlayed + 1
    )
}
```

**Note**: For true isolation, consider dependency injection in future:

```swift
// Future improvement
class TicTacToeGameState {
    private let statistics: StatisticsProtocol
    
    init(statistics: StatisticsProtocol = GameStatistics.shared) {
        self.statistics = statistics
    }
}

// Mock for tests
class MockStatistics: StatisticsProtocol {
    var recordGameCalled = false
    func recordGame(...) { recordGameCalled = true }
}
```

---

## CI/CD Pipeline

### GitHub Actions Workflow

File: `.github/workflows/swift-tests.yml`

```yaml
name: Swift Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: macos-14
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Select Xcode version
      run: sudo xcode-select -s /Applications/Xcode_16.4.app
    
    - name: Run tests
      run: |
        cd TicTacToe
        swift test
```

### What Gets Tested

1. **All pull requests**: Tests run automatically
2. **Pushes to main**: Tests run on merge
3. **macOS runner**: Uses GitHub-hosted macOS machine
4. **Swift Package Manager**: Runs `swift test`

### Test Results

- ✅ **Green check**: All tests passed
- ❌ **Red X**: One or more tests failed
- 🟡 **Yellow dot**: Tests in progress

### Viewing Results

1. Go to GitHub repository
2. Click "Actions" tab
3. Click on workflow run
4. Expand "Run tests" step
5. View detailed output

---

## Coverage Goals

### Current Coverage

| Component | Tests | Coverage |
|-----------|-------|----------|
| GameStatistics | 24 tests | ~85% |
| TicTacToeGameState | 38 tests | ~90% |
| MemoryGameState | 14 tests | ~80% |
| DictionaryGameState | 12 tests | ~55% |
| HangmanGameState | 7 tests | ~70% |
| **Total** | **95 tests** | **~80%** |

### Coverage by Feature

- ✅ **Win detection**: 100% covered (all patterns)
- ✅ **Move validation**: 95% covered
- ✅ **AI opponent**: 90% covered (Easy/Medium/Hard)
- ✅ **Scoring**: 90% covered
- ✅ **Async operations**: 85% covered (mismatch delays, AI moves)
- ⚠️ **API calls**: Not covered (external dependency)
- ⚠️ **UI**: Not covered (UI testing needed)

### Future Coverage Goals

| Component | Current | Target |
|-----------|---------|--------|
| Game Logic | 80% | 90%+ |
| Managers | 0% | 50%+ |
| API Integration | 0% | 60%+ (with mocks) |
| Overall | 80% | 85%+ |

### Viewing Coverage in Xcode

1. Run tests: Cmd+U
2. Open Report Navigator: Cmd+9
3. Select latest test run
4. Click "Coverage" tab
5. Expand files to see line-by-line coverage

---

## Troubleshooting

### Problem: Tests Won't Run

**Error**: "No such module 'GamesApp'"

**Solution**:
```bash
# Clean build folder
cd TicTacToe
rm -rf .build
swift test
```

### Problem: Async Test Timeout

**Error**: "Async test exceeded timeout"

**Cause**: Async operations take longer than expected

**Solution**:
```swift
// Add sufficient wait time for AI moves and delays
@MainActor
func testAIMove() async throws {
    state.changeGameMode(.vsAI)
    state.makeMove(at: 0)
    
    // Hard AI has 1.2s thinking delay
    try await Task.sleep(for: .seconds(1.5))  // Wait longer than delay
    
    // Now AI should have moved
    XCTAssertEqual(state.board.filter { $0 != nil }.count, 2)
}
```

### Problem: Test Timeout

**Error**: "Test timed out"

**Cause**: Infinite loop or async task not completing

**Solution**:
```swift
// Add timeout to async tests
func testAsyncOperation() async throws {
    let expectation = XCTestExpectation(description: "Async completes")
    
    Task {
        await gameState.fetchData()
        expectation.fulfill()
    }
    
    await fulfillment(of: [expectation], timeout: 5.0)
}
```

### Problem: Flaky Tests

**Symptom**: Tests pass sometimes, fail other times

**Common Causes**:
1. **Race conditions**: Use `@MainActor` consistently
2. **Shared state**: Ensure `setUp()` creates fresh state
3. **Random data**: Use seeded random for deterministic tests

**Solution**:
```swift
// ❌ BAD: Shared state between tests
var sharedState = GameState()

func testOne() {
    sharedState.score = 10
}

func testTwo() {
    XCTAssertEqual(sharedState.score, 0)  // FAILS if testOne runs first!
}

// ✅ GOOD: Fresh state each test
var gameState: GameState!

override func setUp() {
    gameState = GameState()  // New instance
}
```

### Problem: @MainActor Errors

**Error**: "Call to main actor-isolated initializer requires main actor"

**Solution**: Mark test class with `@MainActor`:

```swift
@MainActor  // Add this!
final class GameStateTests: XCTestCase {
    var gameState: TicTacToeGameState!
    // ...
}
```

### Problem: Slow Tests

**Symptom**: Tests take >90 seconds (due to AI tests with delays)

**This is Expected**: AI tests include realistic thinking delays
- Easy AI: 0.5s per move
- Medium AI: 0.8s per move  
- Hard AI: 1.2s per move
- 10-game loops can take 60+ seconds

**Optimization**:
```bash
# Run tests in parallel
swift test --parallel

# Run specific test file
swift test --filter TicTacToeGameStateTests

# Skip slow integration tests
swift test --filter TicTacToeGameStateTests/testValidMove
```

---

## Best Practices

### ✅ DO

- Write tests for new features
- Run tests before committing
- Keep tests fast (<1s per test)
- Use descriptive test names
- Test one thing per test
- Clean up state in `tearDown()`

### ❌ DON'T

- Test implementation details
- Share state between tests
- Use hard-coded dates/times
- Skip failing tests (fix or remove)
- Leave debug `print()` statements

---

## Test Checklist

Before submitting a PR, verify:

- [ ] All tests pass (`swift test`)
- [ ] No new warnings in Xcode
- [ ] Added tests for new code
- [ ] Removed/updated tests for deleted code
- [ ] Tests complete in reasonable time (<2 minutes total)
- [ ] Coverage maintained or improved
- [ ] Async tests properly use `await Task.sleep` for delays

---

## Additional Resources

- **XCTest Documentation**: [Apple Developer](https://developer.apple.com/documentation/xctest)
- **Unit Testing Best Practices**: [Swift.org Testing Guide](https://swift.org/getting-started/testing/)
- **CI/CD**: See `.github/workflows/` for pipeline config

---

## Summary

Testing ensures code quality and prevents regressions. Our test suite covers:

- ✅ 95 unit tests across 4 games + statistics
- ✅ ~80% code coverage (up from ~70%)
- ✅ Automated CI/CD on GitHub Actions
- ✅ AI opponent fully tested (22 dedicated tests)
- ✅ Async operations tested (mismatch delays, AI moves)
- ✅ Comprehensive coverage (~90 seconds execution time)

Keep adding tests as the project grows! 🧪✨
