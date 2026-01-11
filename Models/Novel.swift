import Foundation

/// 作品モデル
struct Novel: Identifiable, Codable, Hashable {
    var id: Int
    var genreId: Int
    var title: String
    var updatedAt: Date
    var memo: String
    
    /// 新規作成用イニシャライザ
    init(
        id: Int = 0,
        genreId: Int,
        title: String = "新規作品",
        updatedAt: Date = Date(),
        memo: String = ""
    ) {
        self.id = id
        self.genreId = genreId
        self.title = title
        self.updatedAt = updatedAt
        self.memo = memo
    }
    
    /// 更新日時の表示用フォーマット
    var formattedUpdatedAt: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: updatedAt)
    }
    
    // MARK: - Codable Keys
    enum CodingKeys: String, CodingKey {
        case id
        case genreId = "genre_id"
        case title
        case updatedAt = "updated_at"
        case memo
    }
    
    // MARK: - Hashable Implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(genreId)
        hasher.combine(title)
        hasher.combine(updatedAt.timeIntervalSince1970)
        hasher.combine(memo)
    }
    
    static func == (lhs: Novel, rhs: Novel) -> Bool {
        lhs.id == rhs.id &&
        lhs.genreId == rhs.genreId &&
        lhs.title == rhs.title &&
        lhs.updatedAt.timeIntervalSince1970 == rhs.updatedAt.timeIntervalSince1970 &&
        lhs.memo == rhs.memo
    }
}
