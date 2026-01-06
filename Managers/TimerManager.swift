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

    // バックグラウンド用：通知のキャンセル
    private func cancelNotification() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // バックグラウンド用：通知の予約
    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = isWorkMode ? "集中時間終了！" : "休憩終了！"
        content.body = isWorkMode ? "5分間の休憩に入りましょう。" : "次の25分を始めましょう。"
        content.sound = .default // これで音が鳴ります

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(timeRemaining), repeats: false)
        let request = UNNotificationRequest(identifier: "PomodoroTimer", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}