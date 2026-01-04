import Foundation
import Combine
import AVFoundation

@MainActor
class SimpleTimer: NSObject, ObservableObject {
    @Published var minutes: Int = 25
    @Published var remainingSeconds: Int = 25 * 60
    @Published var isRunning: Bool = false
    
    private var timer: Timer?
    
    func setMinutes(_ mins: Int) {
        let clamped = min(max(mins, 1), 99)
        minutes = clamped
        remainingSeconds = clamped * 60
    }
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }
    
    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func reset() {
        pause()
        remainingSeconds = minutes * 60
    }
    
    private func tick() {
        remainingSeconds -= 1
        if remainingSeconds <= 0 {
            remainingSeconds = 0
            isRunning = false
            timer?.invalidate()
            timer = nil
            playCompletionSound()
        }
    }
    
    func getFormattedTime() -> String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func playCompletionSound() {
        AudioServicesPlaySystemSound(1016)
    }
    
    deinit {
        timer?.invalidate()
    }
}
