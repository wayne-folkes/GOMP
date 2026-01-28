import SwiftUI

struct MemoryGameView: View {
    @StateObject private var gameState = MemoryGameState()
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Text("Memory Game")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Score: \(gameState.score)")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .padding()
                
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                        ForEach(gameState.cards) { card in
                            CardView(card: card)
                                .aspectRatio(2/3, contentMode: .fit)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        gameState.choose(card)
                                    }
                                }
                        }
                    }
                    .padding()
                }
                
                if gameState.isGameOver {
                    Button(action: {
                        withAnimation {
                            gameState.startNewGame()
                        }
                    }) {
                        Text("Play Again")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .foregroundColor(.purple)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding()
                    .transition(.scale)
                }
            }
        }
    }
}

struct CardView: View {
    let card: MemoryCard
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if card.isFaceUp || card.isMatched {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.purple, lineWidth: 3)
                        
                    Text(card.content)
                        .font(.system(size: geometry.size.width * 0.7))
                        .opacity(card.isMatched ? 0.5 : 1)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.orange, Color.red]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(radius: 2)
                }
            }
            .rotation3DEffect(Angle.degrees(card.isFaceUp ? 0 : 180), axis: (x: 0, y: 1, z: 0))
        }
    }
}

#Preview {
    MemoryGameView()
}
