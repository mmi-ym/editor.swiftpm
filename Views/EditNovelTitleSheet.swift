import SwiftUI

/// タイトル編集シート（共通コンポーネント）
/// NovelEditorViewとNovelListViewの両方から使用可能
struct EditNovelTitleSheet: View {
    @ObservedObject private var dataManager = DataManager.shared
    @Binding var novel: Novel
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String = ""
    
    init(novel: Binding<Novel>) {
        self._novel = novel
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
                        dismiss()
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
        dismiss()
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "0"
    }
}
