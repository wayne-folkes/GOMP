import XCTest
@testable import GamesApp

@MainActor
final class DictionaryGameTests: XCTestCase {
    func testDictionaryGameStateInitialization() {
        let state = DictionaryGameState(startImmediately: false)
        state.loadLocalQuestion()
        
        XCTAssertEqual(state.score, 0)
        XCTAssertFalse(state.isGameOver)
        // Ensure options are generated (1 correct + 3 distractors = 4)
        XCTAssertEqual(state.options.count, 4)
    }
}
