import SwiftUI

struct NovelEditorView: View {
    @ObservedObject private var dataManager = DataManager.shared
    @StateObject private var timer = TimerManager()
    @State var novel: Novel
    @State private var bodyText: String
    @State private var showingTitleEditSheet = false
    @State private var showingSettingsView = false
    @State private var showingImageConversion = false
    @State private var showingTimerDialog = false
    @State private var showingTimerCompletionDialog = false
    @Environment(\.dismiss) var dismiss
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @Environment(\.scenePhase) var scenePhase
    @State private var lastActiveDate = Date()
    
    init(novel: Novel, columnVisibility: Binding<NavigationSplitViewVisibility>) {
        self._novel = State(initialValue: novel)
        self._bodyText = State(initialValue: novel.body)
        self._columnVisibility = columnVisibility
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) { // ここで配置を指定
                // 和紙風背景色
                Color(red: 0.992, green: 0.984, blue: 0.969)
                    .ignoresSafeArea()

                // 縦書きエディタ
                VerticalTextEditor(text: $bodyText).padding(.left, 5)

                // 変数名を timer に修正
                PomodoroOverlay(manager: timer)
                    .padding(.bottom, 20) // フッターと被らないよう少し浮かせる
            }
            
            // フッター（文字数表示）
            HStack {
                Label("\(formatNumber(bodyText.count))文字", systemImage: "character")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if timer.isRunning {
                    Divider()
                        .frame(height: 16)
                    
                    Label(timer.getFormattedTime(), systemImage: "timer")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                if bodyText.count != novel.bodyCount {
                    Text("保存中...")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(UIColor.secondarySystemBackground))
        }
        .navigationTitle(novel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingTitleEditSheet = true
                    } label: {
                        Label("タイトルを変更", systemImage: "pencil")
                    }
                    
                    Button {
                        showingSettingsView = true
                    } label: {
                        Label("設定を表示", systemImage: "gearshape")
                    }
                    
                    Button {
                        showingImageConversion = true
                    } label: {
                        Label("画像に変換", systemImage: "photo")
                    }
                    
                    Divider()
                    
                    Button {
                        showingTimerDialog = true
                        if timer.isRunning {
                            timer.stop() // 動作中なら止める
                        } else {
                            timer.start() // 止まっていれば開始
                        }
                    } label: {
                        // Label("タイマー", systemImage: "timer")
                        Label(timer.isRunning ? "タイマーを停止" : "タイマーを開始",
                            systemImage: timer.isRunning ? "timer.circle.fill" : "timer")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                }
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showingTitleEditSheet) {
            EditNovelTitleSheet(novel: $novel)
        }
        .sheet(isPresented: $showingSettingsView) {
            SettingsListView(novel: novel)
        }
        .sheet(isPresented: $showingImageConversion) {
            ImageConversionSheet(isPresented: $showingImageConversion, text: bodyText)
        }
        .sheet(isPresented: $showingTimerDialog) {
            TimerSettingDialog(timer: timer, isPresented: $showingTimerDialog)
        }
        .alert("タイマー完了", isPresented: $showingTimerCompletionDialog) {
            Button("OK") {
                timer.reset()
                showingTimerCompletionDialog = false
            }
        } message: {
            Text("ポモドーロタイマーが完了しました！")
        }
        .onChange(of: timer.isCompleted) { oldValue, newValue in
            if newValue {
                showingTimerCompletionDialog = true
            }
        }
        .onChange(of: bodyText) { oldValue, newValue in
            saveNovel(newValue)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                lastActiveDate = Date() // バックグラウンドに行った時間を記録
            } else if newPhase == .active {
                if timer.isRunning {
                    // 戻ってきた時に、経過した秒数を計算して差し引く
                    let elapsed = Int(Date().timeIntervalSince(lastActiveDate))
                    timer.timeRemaining = max(0, timer.timeRemaining - elapsed)
                }
            }
        }
        .onDisappear {
            saveNovel(bodyText)
            withAnimation {
                columnVisibility = .all
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            timer.updateTick()
        }
    }
    
    // MARK: - Format Number
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "0"
    }
    
    // MARK: - Save Novel
    private func saveNovel(_ text: String) {
        var updatedNovel = novel
        updatedNovel.body = text
        updatedNovel.updateBodyCount()
        dataManager.updateNovel(updatedNovel)
        novel = updatedNovel
    }
}

// MARK: - Placeholder Views
struct NovelSettingsPlaceholderView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Text("設定画面（実装予定）")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        NovelEditorView(
            novel: Novel(
                id: 1,
                genreId: 1,
                title: "魔法学園の冒険",
                body: "これは魔法学園の物語です。\n主人公は魔法の才能を持つ少年で、学園で様々な冒険を繰り広げます。",
                bodyCount: 50
            ),
            columnVisibility: .constant(.all)
        )
    }
}
