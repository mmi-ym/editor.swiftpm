import Foundation

/// 小作品モデル
struct Novel: Identifiable, Codable, Hashable {
    var id: Int
    var genreId: Int
    var title: String
    var body: String
    var updatedAt: Date
    var bodyCount: Int
    var memo: String
    
    /// 新規作成用イニシャライザ
    init(
        id: Int = 0,
        genreId: Int,
        title: String = "新規作品",
        body: String = "",
        updatedAt: Date = Date(),
        bodyCount: Int = 0,
        memo: String = ""
    ) {
        self.id = id
        self.genreId = genreId
        self.title = title
        self.body = body
        self.updatedAt = updatedAt
        self.bodyCount = bodyCount
        self.memo = memo
    }
    
    /// 文字数を自動計算して更新
    mutating func updateBodyCount() {
        // 改行や空白を含む全文字数をカウント
        self.bodyCount = body.count
        self.updatedAt = Date()
    }
    
    /// 更新日時の表示用フォーマット
    var formattedUpdatedAt: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: updatedAt)
    }
    
    /// 本文のプレビュー（最初の50文字）
    var bodyPreview: String {
        let text = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.count > 50 {
            return String(text.prefix(50)) + "..."
        }
        return text
    }
    
    // MARK: - Codable Keys
    enum CodingKeys: String, CodingKey {
        case id
        case genreId = "genre_id"
        case title
        case body
        case updatedAt = "updated_at"
        case bodyCount = "body_count"
        case memo
    }
}
