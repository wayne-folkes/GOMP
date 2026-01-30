import SwiftUI
import Combine

struct CountdownButton: View {
    let action: () -> Void
    let duration: TimeInterval = 10.0
    
    @State private var progress: CGFloat = 1.0
    @State private var isActive: Bool = false
    @State private var timerCancellable: AnyCancellable?
    
    var body: some View {
        Button(action: {
            isActive = false
            timerCancellable?.cancel()
            action()
        }) {
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.gray)
                
                // Progress Bar
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.teal.opacity(0.3))
                        .frame(width: geo.size.width * progress)
                        .animation(.linear(duration: 0.1), value: progress)
                }
                .mask(RoundedRectangle(cornerRadius: 15))
                
                // Text
                Text("Next Word")
                    .font(.headline)
                    .foregroundColor(.teal)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .frame(height: 50)
            .shadow(radius: 5)
        }
        .onAppear {
            progress = 1.0
            isActive = true
            startTimer()
        }
        .onDisappear {
            isActive = false
            timerCancellable?.cancel()
        }
    }
    
    private func startTimer() {
        let step = 0.1
        let totalSteps = duration / step
        let progressStep = 1.0 / totalSteps
        
        timerCancellable = Timer.publish(every: step, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                guard isActive else { 
                    timerCancellable?.cancel()
                    return 
                }
                
                if progress > 0 {
                    progress -= CGFloat(progressStep)
                } else {
                    isActive = false
                    timerCancellable?.cancel()
                    action()
                }
            }
    }
}

