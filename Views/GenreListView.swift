import SwiftUI

struct GenreListView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    @State private var editingGenre: Genre?
    @State private var showingDeleteAlert = false
    @State private var genreToDelete: Genre?
    
    var body: some View {
        NavigationView {
            ZStack {
                if dataManager.genres.isEmpty {
                    emptyStateView
                } else {
                    genreListView
                }
            }
            .navigationTitle("ジャンル一覧")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        // TODO: 執筆記録画面への遷移
                    } label: {
                        Label("執筆記録", systemImage: "calendar")
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
                AddGenreSheet(isPresented: $showingAddSheet)
            }
            .sheet(isPresented: $showingEditSheet) {
                if let genre = editingGenre {
                    EditGenreSheet(
                        genre: genre,
                        isPresented: $showingEditSheet
                    )
                }
            }
            .alert("ジャンルを削除", isPresented: $showingDeleteAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("削除", role: .destructive) {
                    if let genre = genreToDelete {
                        deleteGenre(genre)
                    }
                }
            } message: {
                if let genre = genreToDelete {
                    let novelCount = dataManager.novels.filter { $0.genreId == genre.id }.count
                    if novelCount > 0 {
                        Text("「\(genre.name)」を削除すると、このジャンルに含まれる\(novelCount)作品とすべての関連データも削除されます。この操作は取り消せません。")
                    } else {
                        Text("「\(genre.name)」を削除します。この操作は取り消せません。")
                    }
                }
            }
        }
    }
    
    // MARK: - Genre List View
    private var genreListView: some View {
        List {
            ForEach(dataManager.genres) { genre in
                NavigationLink(destination: NovelListView(genre: genre)) {
                    GenreRow(genre: genre)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        genreToDelete = genre
                        showingDeleteAlert = true
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                    
                    Button {
                        editingGenre = genre
                        showingEditSheet = true
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
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("ジャンルがありません")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("「+」ボタンからジャンルを追加してください")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button {
                showingAddSheet = true
            } label: {
                Label("ジャンルを追加", systemImage: "plus.circle.fill")
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
    
    // MARK: - Delete Genre
    private func deleteGenre(_ genre: Genre) {
        withAnimation {
            dataManager.deleteGenre(genre)
        }
    }
}

// MARK: - Genre Row
struct GenreRow: View {
    let genre: Genre
    @StateObject private var dataManager = DataManager.shared
    
    private var novelCount: Int {
        dataManager.novels.filter { $0.genreId == genre.id }.count
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // カラーインジケーター
            Circle()
                .fill(genre.swiftUIColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "folder.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 18))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(genre.name)
                    .font(.headline)
                
                Text("\(novelCount)作品")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Add Genre Sheet
struct AddGenreSheet: View {
    @StateObject private var dataManager = DataManager.shared
    @Binding var isPresented: Bool
    
    @State private var name: String = ""
    @State private var selectedColor: Color = .blue
    
    private let colorOptions: [Color] = [
        .red, .orange, .yellow, .green, .blue,
        .purple, .pink, .cyan, .indigo, .mint
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("ジャンル名") {
                    TextField("例：ファンタジー", text: $name)
                }
                
                Section("カラー") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(colorOptions, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("ジャンル追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        addGenre()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func addGenre() {
        let colorHex = selectedColor.toHex() ?? "#888888"
        dataManager.addGenre(name: name, color: colorHex)
        isPresented = false
    }
}

// MARK: - Edit Genre Sheet
struct EditGenreSheet: View {
    @StateObject private var dataManager = DataManager.shared
    let genre: Genre
    @Binding var isPresented: Bool
    
    @State private var name: String = ""
    @State private var selectedColor: Color = .blue
    
    private let colorOptions: [Color] = [
        .red, .orange, .yellow, .green, .blue,
        .purple, .pink, .cyan, .indigo, .mint
    ]
    
    init(genre: Genre, isPresented: Binding<Bool>) {
        self.genre = genre
        self._isPresented = isPresented
        self._name = State(initialValue: genre.name)
        self._selectedColor = State(initialValue: genre.swiftUIColor)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("ジャンル名") {
                    TextField("ジャンル名", text: $name)
                }
                
                Section("カラー") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(colorOptions, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("ジャンル編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        updateGenre()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func updateGenre() {
        var updatedGenre = genre
        updatedGenre.name = name
        updatedGenre.color = selectedColor.toHex() ?? genre.color
        dataManager.updateGenre(updatedGenre)
        isPresented = false
    }
}

// MARK: - Preview
#Preview {
    GenreListView()
}
