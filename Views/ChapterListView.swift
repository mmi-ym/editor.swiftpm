import SwiftUI

struct ChapterListView: View {
    let novel: Novel
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @ObservedObject private var dataManager = DataManager.shared
    @State private var showingAddSheet = false
    @State private var editingChapter: Chapter?
    @State private var showingDeleteAlert = false
    @State private var chapterToDelete: Chapter?
    
    private var chapters: [Chapter] {
        dataManager.getChapters(forNovelId: novel.id)
    }
    
    var body: some View {
        ZStack {
            if chapters.isEmpty {
                emptyStateView
            } else {
                chapterListView
            }
        }
        .navigationTitle("\(novel.title)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("追加", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddChapterSheet(novel: novel, isPresented: $showingAddSheet)
        }
        .sheet(item: $editingChapter) { chapter in
            if let index = dataManager.chapters.firstIndex(where: { $0.id == chapter.id }) {
                EditChapterTitleSheet(
                    chapter: Binding(
                        get: { dataManager.chapters[index] },
                        set: { newValue in
                            dataManager.chapters[index] = newValue
                        }
                    )
                )
            }
        }
        .alert("章を削除", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                if let chapter = chapterToDelete {
                    deleteChapter(chapter)
                }
            }
        } message: {
            if let chapter = chapterToDelete {
                Text("「\(chapter.title)」とすべての内容を削除します。この操作は取り消せません。")
            }
        }
    }
    
    // MARK: - Chapter List View
    private var chapterListView: some View {
        List {
            ForEach(chapters) { chapter in
                NavigationLink(value: chapter) {
                    ChapterRow(chapter: chapter)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        chapterToDelete = chapter
                        showingDeleteAlert = true
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                    
                    Button {
                        editingChapter = chapter
                    } label: {
                        Label("編集", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
            .onMove { source, destination in
                var reorderedChapters = chapters
                reorderedChapters.move(fromOffsets: source, toOffset: destination)
                dataManager.reorderChapters(reorderedChapters)
            }
        }
        .listStyle(.insetGrouped)
        .navigationDestination(for: Chapter.self) { chapter in
            ChapterEditorView(chapter: chapter, columnVisibility: $columnVisibility)
                .onAppear {
                    withAnimation {
                        columnVisibility = .detailOnly
                    }
                }
        }
        .environment(\.editMode, .constant(.active))
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("章がありません")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("「+」ボタンから章を追加してください")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button {
                showingAddSheet = true
            } label: {
                Label("章を追加", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
    }
    
    // MARK: - Delete Chapter
    private func deleteChapter(_ chapter: Chapter) {
        withAnimation {
            dataManager.deleteChapter(chapter)
        }
    }
}

// MARK: - Chapter Row
struct ChapterRow: View {
    let chapter: Chapter
    
    var body: some View {
        HStack(spacing: 15) {
            // ドラッグハンドル
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 20))
                .foregroundColor(.gray)
                .frame(width: 30)
            
            // アイコン
            Image(systemName: "doc.text.fill")
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(chapter.title)
                    .font(.headline)
                
                HStack(spacing: 12) {
                    // 文字数
                    Label("\(formatNumber(chapter.bodyCount))文字", systemImage: "character")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // 最終更新日時
                    Label(chapter.formattedUpdatedAt, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "0"
    }
}

// MARK: - Add Chapter Sheet
struct AddChapterSheet: View {
    @ObservedObject private var dataManager = DataManager.shared
    let novel: Novel
    @Binding var isPresented: Bool
    
    @State private var title: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("章タイトル") {
                    TextField("例:第一章 出会い", text: $title)
                }
                
                Section {
                    HStack {
                        Text("作品")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(novel.title)
                    }
                }
            }
            .navigationTitle("章追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        addChapter()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func addChapter() {
        dataManager.addChapter(novelId: novel.id, title: title)
        isPresented = false
    }
}

// MARK: - Edit Chapter Title Sheet
struct EditChapterTitleSheet: View {
    @ObservedObject private var dataManager = DataManager.shared
    @Binding var chapter: Chapter
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    
    init(chapter: Binding<Chapter>) {
        self._chapter = chapter
        self._title = State(initialValue: chapter.wrappedValue.title)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("章タイトル") {
                    TextField("章タイトル", text: $title)
                }
                
                Section("情報") {
                    HStack {
                        Text("文字数")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(formatNumber(chapter.bodyCount))文字")
                    }
                    
                    HStack {
                        Text("最終更新")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(chapter.formattedUpdatedAt)
                    }
                }
            }
            .navigationTitle("章編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        updateChapter()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func updateChapter() {
        chapter.title = title
        dataManager.updateChapter(chapter)
        dismiss()
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "0"
    }
}

// MARK: - Chapter Editor View (Placeholder)
struct ChapterEditorView: View {
    let chapter: Chapter
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
    var body: some View {
        Text("Chapter Editor - Coming Soon")
            .navigationTitle(chapter.title)
    }
}

#Preview {
    NavigationView {
        ChapterListView(
            novel: Novel(id: 1, genreId: 1, title: "魔法学園の冒険"),
            columnVisibility: .constant(.all)
        )
    }
}
