import SwiftUI
import Combine

struct MemoryCard: Identifiable {
    let id = UUID()
    let content: String
    var isFaceUp: Bool = false
    var isMatched: Bool = false
}

class MemoryGameState: ObservableObject {
    @Published var cards: [MemoryCard] = []
    @Published var score: Int = 0
    @Published var isGameOver: Bool = false
    
    private var indexOfTheOneAndOnlyFaceUpCard: Int?
    
    private let emojis = ["🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐯", "🐨", "🐻", "🐼", "🐻‍❄️", "🐽", "🐸", "🐵", "🙈", "🙉", "🙊", "🦅"]
    
    init() {
        startNewGame()
    }
    
    func startNewGame() {
        var newCards: [MemoryCard] = []
        // We need 18 pairs for 36 cards
        let selectedEmojis = emojis.prefix(18) 
        
        for emoji in selectedEmojis {
            newCards.append(MemoryCard(content: emoji))
            newCards.append(MemoryCard(content: emoji))
        }
        
        cards = newCards.shuffled()
        score = 0
        isGameOver = false
        indexOfTheOneAndOnlyFaceUpCard = nil
    }
    
    func choose(_ card: MemoryCard) {
        if let chosenIndex = cards.firstIndex(where: { $0.id == card.id }),
           !cards[chosenIndex].isFaceUp,
           !cards[chosenIndex].isMatched
        {
            if let potentialMatchIndex = indexOfTheOneAndOnlyFaceUpCard {
                if cards[chosenIndex].content == cards[potentialMatchIndex].content {
                    cards[chosenIndex].isMatched = true
                    cards[potentialMatchIndex].isMatched = true
                    score += 2
                } else {
                    score -= 1
                }
                cards[chosenIndex].isFaceUp = true
                indexOfTheOneAndOnlyFaceUpCard = nil
            } else {
                for index in cards.indices {
                    if cards[index].isFaceUp && !cards[index].isMatched {
                         cards[index].isFaceUp = false
                    }
                }
                cards[chosenIndex].isFaceUp = true
                indexOfTheOneAndOnlyFaceUpCard = chosenIndex
            }
            
            checkForWin()
        }
    }
    
    private func checkForWin() {
        if cards.allSatisfy({ $0.isMatched }) {
            isGameOver = true
        }
    }
}
