import SwiftUI

struct ChapterListView: View {
    let novel: Novel
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @ObservedObject private var dataManager = DataManager.shared
    @State private var showingAddSheet = false
    @State private var editingChapter: Chapter?
    @State private var showingDeleteAlert = false
    @State private var chapterToDelete: Chapter?
    @State private var isEditMode = false
    
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
            ToolbarItem(placement: .navigationBarLeading) {
                if !chapters.isEmpty {
                    Button(isEditMode ? "完了" : "並び替え") {
                        withAnimation {
                            isEditMode.toggle()
                        }
                    }
                }
            }
            
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
        .environment(\.editMode, .constant(isEditMode ? .active : .inactive))
        .navigationDestination(for: Chapter.self) { chapter in
            ChapterEditorView(chapter: chapter, columnVisibility: $columnVisibility)
                .onAppear {
                    withAnimation {
                        columnVisibility = .detailOnly
                    }
                }
        }
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

// MARK: - Chapter Editor View
struct ChapterEditorView: View {
    @ObservedObject private var dataManager = DataManager.shared
    @StateObject private var timer = SimpleTimer()
    @State var chapter: Chapter
    @State private var bodyText: String
    @State private var showingTitleEditSheet = false
    @State private var showingImageConversion = false
    @State private var showingTimerDialog = false
    @State private var showingTimerCompletionDialog = false
    @Environment(\.dismiss) var dismiss
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
    init(chapter: Chapter, columnVisibility: Binding<NavigationSplitViewVisibility>) {
        self._chapter = State(initialValue: chapter)
        self._bodyText = State(initialValue: chapter.body)
        self._columnVisibility = columnVisibility
    }
    
    private var novel: Novel? {
        dataManager.novels.first { $0.id == chapter.novelId }
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
                
                if bodyText.count != chapter.bodyCount {
                    Text("保存中...")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(UIColor.secondarySystemBackground))
        }
        .navigationTitle(chapter.title)
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
            if let index = dataManager.chapters.firstIndex(where: { $0.id == chapter.id }) {
                EditChapterTitleSheet(
                    chapter: Binding(
                        get: { dataManager.chapters[index] },
                        set: { newValue in
                            dataManager.chapters[index] = newValue
                            chapter = newValue
                        }
                    )
                )
            }
        }
        .sheet(isPresented: $showingImageConversion) {
            ImageConversionSheet(
                isPresented: $showingImageConversion,
                text: bodyText,
                novelTitle: novel?.title,
                chapterTitle: chapter.title
            )
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
            saveChapter(newValue)
        }
        .onDisappear {
            saveChapter(bodyText)
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
    
    // MARK: - Save Chapter
    private func saveChapter(_ text: String) {
        var updatedChapter = chapter
        updatedChapter.body = text
        updatedChapter.updateBodyCount()
        dataManager.updateChapter(updatedChapter)
        chapter = updatedChapter
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
