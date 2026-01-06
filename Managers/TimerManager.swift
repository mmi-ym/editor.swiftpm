import Foundation
import UserNotifications
import AudioToolbox // これを追加
import SwiftUI      // ObservableObjectのために必要

class TimerManager: ObservableObject {
    @Published var timeRemaining = 1 * 60
    @Published var isRunning = false
    @Published var isWorkMode = true
    @Published var isCompleted = false // 完了フラグ

    let workDuration = 1 * 60
    let relaxDuration = 1 * 60

    func start() { isRunning = true; scheduleNotification() }
    func stop() { isRunning = false; cancelNotification() }
    func reset() {
        isRunning = false
        isWorkMode = true
        isCompleted = false
        timeRemaining = workDuration
    }

    func updateTick() {
        guard isRunning else { return }
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            // モード切替
            isWorkMode.toggle()
            timeRemaining = isWorkMode ? workDuration : relaxDuration
            isCompleted = true // View側でアラートを出すトリガー
            AudioServicesPlaySystemSound(1005)
            scheduleNotification()
        }
    }

    func getFormattedTime() -> String {
        String(format: "%02d:%02d", timeRemaining / 60, timeRemaining % 60)
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}