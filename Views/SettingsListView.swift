import SwiftUI

struct SettingsListView: View {
    @ObservedObject private var dataManager = DataManager.shared
    let novel: Novel
    @State private var showingAddSheet = false
    @State private var showingDeleteAlert = false
    @State private var settingToDelete: NovelSettings?
    @Environment(\.dismiss) var dismiss
    
    private var groupedSettings: [NovelSettings.AttributeType: [NovelSettings]] {
        let settings = dataManager.getNovelSettings(forNovelId: novel.id)
        return Dictionary(grouping: settings) { $0.attribute }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if dataManager.getNovelSettings(forNovelId: novel.id).isEmpty {
                    emptyStateView
                } else {
                    settingsListView
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("エディタ")
                        }
                    }
                }
            }
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
                AddSettingsSheet(novel: novel, isPresented: $showingAddSheet)
            }
            .alert("設定を削除", isPresented: $showingDeleteAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("削除", role: .destructive) {
                    if let setting = settingToDelete {
                        deleteSetting(setting)
                    }
                }
            } message: {
                if let setting = settingToDelete {
                    Text("「\(setting.displayTitle)」を削除します。この操作は取り消せません。")
                }
            }
        }
    }
    
    // MARK: - Settings List View
    private var settingsListView: some View {
        List {
            ForEach(NovelSettings.AttributeType.allCases, id: \.self) { type in
                if let settings = groupedSettings[type], !settings.isEmpty {
                    Section {
                        ForEach(settings) { setting in
                            NavigationLink(destination: SettingsEditorView(novel: novel, settings: setting)) {
                                SettingRow(setting: setting)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    settingToDelete = setting
                                    showingDeleteAlert = true
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: type.icon)
                            Text(type.displayName)
                        }
                        .font(.headline)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("設定がありません")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("「+」ボタンから設定を追加してください")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button {
                showingAddSheet = true
            } label: {
                Label("設定を追加", systemImage: "plus.circle.fill")
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
    
    // MARK: - Delete Setting
    private func deleteSetting(_ setting: NovelSettings) {
        withAnimation {
            dataManager.deleteNovelSettings(setting)
        }
    }
}

// MARK: - Setting Row
struct SettingRow: View {
    let setting: NovelSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(setting.displayTitle)
                .font(.headline)
            
            if !setting.body.isEmpty {
                Text(setting.bodyPreview)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Settings Sheet
struct AddSettingsSheet: View {
    @ObservedObject private var dataManager = DataManager.shared
    let novel: Novel
    @Binding var isPresented: Bool
    
    @State private var selectedType: NovelSettings.AttributeType = .character
    @State private var title: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("分類") {
                    Picker("分類を選択", selection: $selectedType) {
                        ForEach(NovelSettings.AttributeType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("タイトル") {
                    TextField("例：主人公の設定", text: $title)
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
            .navigationTitle("設定追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        addSetting()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func addSetting() {
        dataManager.addNovelSettings(novelId: novel.id, attribute: selectedType, title: title)
        isPresented = false
    }
}

// MARK: - Settings Editor View
struct SettingsEditorView: View {
    let novel: Novel
    @State var settings: NovelSettings
    @ObservedObject private var dataManager = DataManager.shared
    @State private var bodyText: String
    @State private var showingTitleEditSheet = false
    @Environment(\.dismiss) var dismiss
    
    // キャラ設定テンプレート
    private let characterTemplate = """
⚫︎年齢
⚫︎誕生日
⚫︎性別
⚫︎身長
⚫︎体重
⚫︎血液型
⚫︎職業
⚫︎出身地
⚫︎現在の住まい
⚫︎利き手
⚫︎イメージカラー
⚫︎家族構成
⚫︎家族との仲、家族環境
⚫︎コンプレックス
⚫︎トラウマ
⚫︎よくしていること
⚫︎特技
⚫︎怒りの沸点
⚫︎根に持つかどうか
⚫︎夢、野心、願い
⚫︎好きな食べ物
⚫︎苦手な食べ物
⚫︎好きな物事
⚫︎苦手な物事
⚫︎好みのタイプ
⚫︎苦手なタイプ
⚫︎好きな場所
⚫︎休日の過ごし方
⚫︎一人称
⚫︎二人称
⚫︎周囲の人とのかかわりについて
⚫︎所持品
⚫︎過去
⚫︎その他特記事項、関連用語
"""
    
    init(novel: Novel, settings: NovelSettings) {
        self.novel = novel
        self._settings = State(initialValue: settings)
        
        // 新規キャラ設定の場合はテンプレートを適用
        if settings.attribute == .character && settings.body.isEmpty {
            self._bodyText = State(initialValue: characterTemplate)
        } else {
            self._bodyText = State(initialValue: settings.body)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 横書きエディタ（ゴシック体）
            TextEditor(text: $bodyText)
                .font(.custom("HiraginoSans-W3", size: 17))
                .padding()
                .scrollContentBackground(.hidden)
                .background(Color(UIColor.systemBackground))
            
            // フッター（文字数表示）
            HStack {
                Label("\(formatNumber(bodyText.count))文字", systemImage: "character")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if bodyText != settings.body {
                    Text("保存中...")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(UIColor.secondarySystemBackground))
        }
        .navigationTitle(settings.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("設定一覧")
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingTitleEditSheet = true
                    } label: {
                        Label("タイトルと分類を変更", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingTitleEditSheet) {
            EditSettingsTitleSheet(settings: $settings, isPresented: $showingTitleEditSheet)
        }
        .onChange(of: bodyText) { oldValue, newValue in
            saveSettings()
        }
        .onAppear {
            // 初回表示時にキャラ設定テンプレートを保存
            if settings.attribute == .character && settings.body.isEmpty {
                saveSettings()
            }
        }
        .onDisappear {
            saveSettings()
        }
    }
    
    private func saveSettings() {
        var updated = settings
        updated.body = bodyText
        dataManager.updateNovelSettings(updated)
        settings = updated
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "0"
    }
}

// MARK: - Edit Settings Title Sheet
struct EditSettingsTitleSheet: View {
    @ObservedObject private var dataManager = DataManager.shared
    @Binding var settings: NovelSettings
    @Binding var isPresented: Bool
    
    @State private var title: String = ""
    @State private var selectedType: NovelSettings.AttributeType
    
    init(settings: Binding<NovelSettings>, isPresented: Binding<Bool>) {
        self._settings = settings
        self._isPresented = isPresented
        self._title = State(initialValue: settings.wrappedValue.title)
        self._selectedType = State(initialValue: settings.wrappedValue.attribute)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("分類") {
                    Picker("分類を選択", selection: $selectedType) {
                        ForEach(NovelSettings.AttributeType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("タイトル") {
                    TextField("タイトル", text: $title)
                }
            }
            .navigationTitle("設定編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        updateSettings()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func updateSettings() {
        var updated = settings
        updated.title = title
        updated.attribute = selectedType
        dataManager.updateNovelSettings(updated)
        settings = updated
        isPresented = false
    }
}

// MARK: - Preview
#Preview {
    SettingsListView(novel: Novel(
        id: 1,
        genreId: 1,
        title: "魔法学園の冒険"
    ))
}
