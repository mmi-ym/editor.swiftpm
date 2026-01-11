import SwiftUI

struct NovelEditorView: View {
    @ObservedObject private var dataManager = DataManager.shared
    @StateObject private var timer = SimpleTimer()
    @State var novel: Novel
    @State private var bodyText: String
    @State private var showingTitleEditSheet = false
    @State private var showingSettingsView = false
    @State private var showingImageConversion = false
    @State private var showingTimerDialog = false
    @State private var showingTimerCompletionDialog = false
    @Environment(\.dismiss) var dismiss
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
    init(novel: Novel, columnVisibility: Binding<NavigationSplitViewVisibility>) {
        self._novel = State(initialValue: novel)
        self._bodyText = State(initialValue: "")  // 空文字で初期化（このビューは使用されない）
        self._columnVisibility = columnVisibility
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 縦書きエディタ
            ZStack {
                // 和紙風背景色
                Color(red: 0.992, green: 0.984, blue: 0.969)
                    .ignoresSafeArea()
                
                // 縦書きエディタ
                VerticalTextEditor(text: $bodyText)
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
                
                Text("保存中...")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .opacity(0)  // 常に非表示（このビューは使用されない）
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
                    } label: {
                        Label("タイマー", systemImage: "timer")
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
        .onDisappear {
            saveNovel(bodyText)
            withAnimation {
                columnVisibility = .all
            }
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
        // このビューは使用されないため、何もしない
        // Chapterの編集にはChapterEditorViewを使用
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
                title: "魔法学園の冒険"
            ),
            columnVisibility: .constant(.all)
        )
    }
}
