import Foundation

/// アプリ全体のデータを管理するマネージャークラス
@MainActor
class DataManager: ObservableObject {
    // MARK: - Published Properties
    @Published var genres: [Genre] = []
    @Published var novels: [Novel] = []
    @Published var novelSettings: [NovelSettings] = []
    @Published var writeLogs: [WriteLog] = []
    @Published var thoughts: [Thought] = []
    
    // MARK: - ID管理用カウンター
    private var nextGenreId: Int = 1
    private var nextNovelId: Int = 1
    private var nextNovelSettingsId: Int = 1
    private var nextThoughtId: Int = 1
    
    // MARK: - ファイルパス
    private let genresFileName = "genres.json"
    private let novelsFileName = "novels.json"
    private let settingsFileName = "novel_settings.json"
    private let logsFileName = "write_logs.json"
    private let thoughtsFileName = "thoughts.json"
    private let countersFileName = "id_counters.json"
    
    // MARK: - Singleton
    static let shared = DataManager()
    
    private init() {
        loadAllData()
    }
    
    // MARK: - Load Data
    func loadAllData() {
        loadCounters()
        genres = load(fileName: genresFileName) ?? []
        novels = load(fileName: novelsFileName) ?? []
        novelSettings = load(fileName: settingsFileName) ?? []
        writeLogs = load(fileName: logsFileName) ?? []
        thoughts = load(fileName: thoughtsFileName) ?? []
        
        // サンプルデータの作成（初回起動時）
        if genres.isEmpty {
            createSampleData()
        }
    }
    
    // MARK: - Save Data
    func saveAllData() {
        save(data: genres, fileName: genresFileName)
        save(data: novels, fileName: novelsFileName)
        save(data: novelSettings, fileName: settingsFileName)
        save(data: writeLogs, fileName: logsFileName)
        save(data: thoughts, fileName: thoughtsFileName)
        saveCounters()
    }
    
    // MARK: - Generic Load/Save
    private func load<T: Codable>(fileName: String) -> T? {
        guard let url = getDocumentDirectory()?.appendingPathComponent(fileName) else {
            return nil
        }
        
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(T.self, from: data)
    }
    
    private func save<T: Codable>(data: T, fileName: String) {
        guard let url = getDocumentDirectory()?.appendingPathComponent(fileName) else {
            return
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        if let encoded = try? encoder.encode(data) {
            try? encoded.write(to: url)
        }
    }
    
    private func getDocumentDirectory() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    // MARK: - ID Counter Management
    private struct IDCounters: Codable {
        var genreId: Int
        var novelId: Int
        var novelSettingsId: Int
        var thoughtId: Int
    }
    
    private func loadCounters() {
        if let counters: IDCounters = load(fileName: countersFileName) {
            nextGenreId = counters.genreId
            nextNovelId = counters.novelId
            nextNovelSettingsId = counters.novelSettingsId
            nextThoughtId = counters.thoughtId
        }
    }
    
    private func saveCounters() {
        let counters = IDCounters(
            genreId: nextGenreId,
            novelId: nextNovelId,
            novelSettingsId: nextNovelSettingsId,
            thoughtId: nextThoughtId
        )
        save(data: counters, fileName: countersFileName)
    }
    
    // MARK: - Genre Operations
    func addGenre(name: String, color: String = "#888888") {
        let genre = Genre(id: nextGenreId, name: name, color: color)
        nextGenreId += 1
        genres.append(genre)
        saveAllData()
    }
    
    func updateGenre(_ genre: Genre) {
        if let index = genres.firstIndex(where: { $0.id == genre.id }) {
            genres[index] = genre
            saveAllData()
        }
    }
    
    func deleteGenre(_ genre: Genre) {
        // ジャンルに紐づく作品も削除
        novels.removeAll { $0.genreId == genre.id }
        genres.removeAll { $0.id == genre.id }
        saveAllData()
    }
    
    // MARK: - Novel Operations
    func addNovel(genreId: Int, title: String = "新規作品") {
        let novel = Novel(id: nextNovelId, genreId: genreId, title: title)
        nextNovelId += 1
        novels.append(novel)
        saveAllData()
    }
    
    func updateNovel(_ novel: Novel) {
        if let index = novels.firstIndex(where: { $0.id == novel.id }) {
            novels[index] = novel
            saveAllData()
        }
    }
    
    func deleteNovel(_ novel: Novel) {
        // 作品に紐づく設定、ログ、思考も削除
        novelSettings.removeAll { $0.novelId == novel.id }
        writeLogs.removeAll { $0.novelId == novel.id }
        thoughts.removeAll { $0.novelId == novel.id }
        novels.removeAll { $0.id == novel.id }
        saveAllData()
    }
    
    func getNovels(forGenreId genreId: Int) -> [Novel] {
        novels.filter { $0.genreId == genreId }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
    
    // MARK: - NovelSettings Operations
    func addNovelSettings(novelId: Int, attribute: NovelSettings.AttributeType = .character, title: String = "") {
        let settings = NovelSettings(id: nextNovelSettingsId, novelId: novelId, attribute: attribute, title: title)
        nextNovelSettingsId += 1
        novelSettings.append(settings)
        saveAllData()
    }
    
    func updateNovelSettings(_ settings: NovelSettings) {
        if let index = novelSettings.firstIndex(where: { $0.id == settings.id }) {
            novelSettings[index] = settings
            saveAllData()
        }
    }
    
    func deleteNovelSettings(_ settings: NovelSettings) {
        novelSettings.removeAll { $0.id == settings.id }
        saveAllData()
    }
    
    func getNovelSettings(forNovelId novelId: Int) -> [NovelSettings] {
        novelSettings.filter { $0.novelId == novelId }
    }
    
    // MARK: - WriteLog Operations
    func addOrUpdateWriteLog(novelId: Int, date: Date, writeCount: Int, totalCount: Int = 0, workingTime: Int = 0, memo: String = "") {
        // 同じ日付のログがあれば更新、なければ追加
        if let index = writeLogs.firstIndex(where: {
            $0.novelId == novelId && Calendar.current.isDate($0.date, inSameDayAs: date)
        }) {
            writeLogs[index].writeCount = writeCount
            writeLogs[index].totalCount = totalCount
            writeLogs[index].workingTime = workingTime
            writeLogs[index].memo = memo
        } else {
            let log = WriteLog(date: date, novelId: novelId, writeCount: writeCount, totalCount: totalCount, workingTime: workingTime, memo: memo)
            writeLogs.append(log)
        }
        saveAllData()
    }
    
    func deleteWriteLog(novelId: Int, date: Date) {
        writeLogs.removeAll {
            $0.novelId == novelId && Calendar.current.isDate($0.date, inSameDayAs: date)
        }
        saveAllData()
    }
    
    func getWriteLogs(forNovelId novelId: Int) -> [WriteLog] {
        writeLogs.filter { $0.novelId == novelId }
            .sorted { $0.date > $1.date }
    }
    
    func getWriteLog(forNovelId novelId: Int, date: Date) -> WriteLog? {
        writeLogs.first {
            $0.novelId == novelId && Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }
    
    // MARK: - Thought Operations
    func addThought(novelId: Int, body: String = "") {
        let thought = Thought(id: nextThoughtId, novelId: novelId, body: body)
        nextThoughtId += 1
        thoughts.append(thought)
        saveAllData()
    }
    
    func updateThought(_ thought: Thought) {
        if let index = thoughts.firstIndex(where: { $0.id == thought.id }) {
            thoughts[index] = thought
            saveAllData()
        }
    }
    
    func deleteThought(_ thought: Thought) {
        thoughts.removeAll { $0.id == thought.id }
        saveAllData()
    }
    
    func getThoughts(forNovelId novelId: Int) -> [Thought] {
        thoughts.filter { $0.novelId == novelId }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Sample Data
    private func createSampleData() {
        addGenre(name: "ファンタジー", color: "#FF6B6B")
        addGenre(name: "SF", color: "#4ECDC4")
        addGenre(name: "ミステリー", color: "#95E1D3")
        
        // サンプル作品を追加
        if let fantasyGenre = genres.first(where: { $0.name == "ファンタジー" }) {
            addNovel(genreId: fantasyGenre.id, title: "魔法学園の冒険")
            addNovel(genreId: fantasyGenre.id, title: "竜との契約")
            addNovel(genreId: fantasyGenre.id, title: "失われた王国")
            
            // 最初の作品に本文と文字数を設定
            if var novel = novels.first {
                novel.body = "これは魔法学園の物語です。主人公は魔法の才能を持つ少年で、学園で様々な冒険を繰り広げます。"
                novel.updateBodyCount()
                updateNovel(novel)
                
                // 設定データを追加
                addNovelSettings(novelId: novel.id, attribute: .character, title: "主人公 アレク")
                addNovelSettings(novelId: novel.id, attribute: .character, title: "ヒロイン エリナ")
                addNovelSettings(novelId: novel.id, attribute: .plot, title: "第一章 入学")
                addNovelSettings(novelId: novel.id, attribute: .plot, title: "第二章 試練")
                addNovelSettings(novelId: novel.id, attribute: .other, title: "世界観設定")
            }
        }
        
        if let sfGenre = genres.first(where: { $0.name == "SF" }) {
            addNovel(genreId: sfGenre.id, title: "時空を超えて")
            addNovel(genreId: sfGenre.id, title: "AI革命")
        }
    }
}
