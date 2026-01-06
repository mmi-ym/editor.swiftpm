import SwiftUI
struct PomodoroOverlay: View {
    // @StateObject ではなく @ObservedObject にして、親から共有される
    @ObservedObject var manager: TimerManager
    @Environment(\.scenePhase) var scenePhase
    @State private var lastActiveDate = Date()

    var body: some View {
        if manager.isRunning { // 実行中のみ表示
            VStack {
                HStack {
                    Text(manager.isWorkMode ? "集中" : "休憩")
                        .font(.caption)
                    Text(manager.getFormattedTime()) // managerの共通メソッドを使う
                        .font(.system(.body, design: .monospaced))
                }
                .padding(8)
                .background(Capsule().fill(Color.secondary.opacity(0.8))) // 視認性アップ
            }
            .padding()
            // .onReceive は親側で一括管理するか、ここで行う
        }
    }
}