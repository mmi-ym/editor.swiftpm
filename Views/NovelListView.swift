import SwiftUI

struct NovelListView: View {
    let genre: Genre
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @ObservedObject private var dataManager = DataManager.shared
    @State private var showingAddSheet = false
    @State private var editingNovel: Novel?
    @State private var showingDeleteAlert = false
    @State private var novelToDelete: Novel?
    
    private var novels: [Novel] {
        dataManager.getNovels(forGenreId: genre.id)
    }
    
    var body: some View {
        ZStack {
            if novels.isEmpty {
                emptyStateView
            } else {
                novelListView
            }
        }
        .navigationTitle("\(genre.name) 作品一覧")
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
            AddNovelSheet(genre: genre, isPresented: $showingAddSheet)
        }
        .sheet(item: $editingNovel) { novel in
            if let index = dataManager.novels.firstIndex(where: { $0.id == novel.id }) {
                EditNovelTitleSheet(
                    novel: Binding(
                        get: { dataManager.novels[index] },
                        set: { newValue in
                            dataManager.novels[index] = newValue
                        }
                    )
                )
            }
        }
        .alert("作品を削除", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                if let novel = novelToDelete {
                    deleteNovel(novel)
                }
            }
        } message: {
            if let novel = novelToDelete {
                Text("「\(novel.title)」とすべての関連データを削除します。この操作は取り消せません。")
            }
        }
    }
    
    // MARK: - Novel List View
    private var novelListView: some View {
        List {
            ForEach(novels) { novel in
                NavigationLink(destination: NovelEditorView(novel: novel)) {
                    NovelRow(novel: novel)
                }
                .onTapGesture {
                    withAnimation {
                        columnVisibility = .detailOnly
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        novelToDelete = novel
                        showingDeleteAlert = true
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                    
                    Button {
                        editingNovel = novel
                    } label: {
                        Label("編集", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("作品がありません")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("「+」ボタンから作品を追加してください")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button {
                showingAddSheet = true
            } label: {
                Label("作品を追加", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
                    .background(genre.swiftUIColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
    }
    
    // MARK: - Delete Novel
    private func deleteNovel(_ novel: Novel) {
        withAnimation {
            dataManager.deleteNovel(novel)
        }
    }
}

// MARK: - Novel Row
struct NovelRow: View {
    let novel: Novel
    
    var body: some View {
        HStack(spacing: 15) {
            // アイコン
            Image(systemName: "doc.text.fill")
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(novel.title)
                    .font(.headline)
                
                HStack(spacing: 12) {
                    // 文字数
                    Label("\(formatNumber(novel.bodyCount))文字", systemImage: "character")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // 最終更新日時
                    Label(novel.formattedUpdatedAt, systemImage: "clock")
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

// MARK: - Add Novel Sheet
struct AddNovelSheet: View {
    @ObservedObject private var dataManager = DataManager.shared
    let genre: Genre
    @Binding var isPresented: Bool
    
    @State private var title: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("作品タイトル") {
                    TextField("例：魔法学園の冒険", text: $title)
                }
                
                Section {
                    HStack {
                        Text("ジャンル")
                            .foregroundColor(.secondary)
                        Spacer()
                        HStack(spacing: 8) {
                            Circle()
                                .fill(genre.swiftUIColor)
                                .frame(width: 20, height: 20)
                            Text(genre.name)
                        }
                    }
                }
            }
            .navigationTitle("作品追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        addNovel()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func addNovel() {
        dataManager.addNovel(genreId: genre.id, title: title)
        isPresented = false
    }
}

// MARK: - Edit Novel Sheet
struct EditNovelSheet: View {
    @ObservedObject private var dataManager = DataManager.shared
    let novel: Novel
    @Binding var isPresented: Bool
    
    @State private var title: String = ""
    
    init(novel: Novel, isPresented: Binding<Bool>) {
        self.novel = novel
        self._isPresented = isPresented
        self._title = State(initialValue: novel.title)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("作品タイトル") {
                    TextField("作品タイトル", text: $title)
                }
                
                Section("情報") {
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
            .navigationTitle("作品編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        updateNovel()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func updateNovel() {
        var updatedNovel = novel
        updatedNovel.title = title
        dataManager.updateNovel(updatedNovel)
        isPresented = false
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "0"
    }
}

#Preview {
    NavigationView {
        NovelListView(
            genre: Genre(id: 1, name: "ファンタジー", color: "#FF6B6B"),
            columnVisibility: .constant(.all)
        )
    }
}
