import SwiftUI

struct NovelEditorView: View {
    @ObservedObject private var dataManager = DataManager.shared
    @State var novel: Novel
    @State private var bodyText: String
    @State private var showingTitleEditSheet = false
    @State private var showingSettingsView = false
    @State private var showingImageConversion = false
    @Environment(\.dismiss) var dismiss
    
    init(novel: Novel) {
        self._novel = State(initialValue: novel)
        self._bodyText = State(initialValue: novel.body)
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
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                }
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showingTitleEditSheet) {
            EditNovelTitleSheet(novel: $novel, isPresented: $showingTitleEditSheet)
        }
        .sheet(isPresented: $showingSettingsView) {
            SettingsListView(novel: novel)
        }
        .sheet(isPresented: $showingImageConversion) {
            ImageConversionPlaceholderView()
        }
        .onChange(of: bodyText) { oldValue, newValue in
            saveNovel(newValue)
        }
        .onDisappear {
            saveNovel(bodyText)
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

// MARK: - Edit Novel Title Sheet
struct EditNovelTitleSheet: View {
    @ObservedObject private var dataManager = DataManager.shared
    @Binding var novel: Novel
    @Binding var isPresented: Bool
    
    @State private var title: String = ""
    
    init(novel: Binding<Novel>, isPresented: Binding<Bool>) {
        self._novel = novel
        self._isPresented = isPresented
        self._title = State(initialValue: novel.wrappedValue.title)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("作品タイトル") {
                    TextField("タイトル", text: $title)
                        .font(.body)
                }
                
                Section {
                    HStack {
                        Text("文字数")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(formatNumber(novel.bodyCount))文字")
                    }
                    
                    HStack {
                        Text("最終更新")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(novel.formattedUpdatedAt)
                    }
                }
            }
            .navigationTitle("タイトル変更")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        updateTitle()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func updateTitle() {
        var updatedNovel = novel
        updatedNovel.title = title
        dataManager.updateNovel(updatedNovel)
        novel = updatedNovel
        isPresented = false
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "0"
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

struct ImageConversionPlaceholderView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "photo.badge.arrow.down")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("画像変換機能")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("実装予定")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("画像に変換")
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
        NovelEditorView(novel: Novel(
            id: 1,
            genreId: 1,
            title: "魔法学園の冒険",
            body: "これは魔法学園の物語です。\n主人公は魔法の才能を持つ少年で、学園で様々な冒険を繰り広げます。",
            bodyCount: 50
        ))
    }
}
