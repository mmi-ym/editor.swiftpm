import Foundation

/// 章モデル
struct Chapter: Identifiable, Codable, Hashable {
    var id: Int
    var novelId: Int  // 所属する作品のID
    var title: String
    var body: String
    var updatedAt: Date
    var bodyCount: Int
    var memo: String
    var order: Int  // 章の順序
    
    /// 新規作成用イニシャライザ
    init(
        id: Int = 0,
        novelId: Int,
        title: String = "新規章",
        body: String = "",
        updatedAt: Date = Date(),
        bodyCount: Int = 0,
        memo: String = "",
        order: Int = 0
    ) {
        self.id = id
        self.novelId = novelId
        self.title = title
        self.body = body
        self.updatedAt = updatedAt
        self.bodyCount = bodyCount
        self.memo = memo
        self.order = order
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
        case novelId = "novel_id"
        case title
        case body
        case updatedAt = "updated_at"
        case bodyCount = "body_count"
        case memo
        case order
    }
    
    // MARK: - Hashable Implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(novelId)
        hasher.combine(title)
        hasher.combine(body)
        hasher.combine(updatedAt.timeIntervalSince1970)
        hasher.combine(bodyCount)
        hasher.combine(memo)
        hasher.combine(order)
    }
    
    static func == (lhs: Chapter, rhs: Chapter) -> Bool {
        lhs.id == rhs.id &&
        lhs.novelId == rhs.novelId &&
        lhs.title == rhs.title &&
        lhs.body == rhs.body &&
        lhs.updatedAt.timeIntervalSince1970 == rhs.updatedAt.timeIntervalSince1970 &&
        lhs.bodyCount == rhs.bodyCount &&
        lhs.memo == rhs.memo &&
        lhs.order == rhs.order
    }
}
