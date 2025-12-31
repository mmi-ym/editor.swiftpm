import Foundation

/// 思考・アイデアメモモデル
struct Thought: Identifiable, Codable, Hashable {
    var id: Int
    var novelId: Int
    var body: String
    var createdAt: Date
    
    /// 新規作成用イニシャライザ
    init(
        id: Int = 0,
        novelId: Int,
        body: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.novelId = novelId
        self.body = body
        self.createdAt = createdAt
    }
    
    /// 作成日時の表示用フォーマット
    var formattedCreatedAt: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: createdAt)
    }
    
    /// 相対的な日時表示（例：「2時間前」「昨日」）
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    /// 本文のプレビュー（最初の50文字）
    var bodyPreview: String {
        let text = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.count > 50 {
            return String(text.prefix(50)) + "..."
        }
        return text.isEmpty ? "内容なし" : text
    }
    
    /// 本文の最初の行をタイトルとして使用
    var titleFromBody: String {
        let lines = body.components(separatedBy: .newlines)
        let firstLine = lines.first?.trimmingCharacters(in: .whitespaces) ?? ""
        if firstLine.isEmpty {
            return "無題のメモ"
        }
        if firstLine.count > 20 {
            return String(firstLine.prefix(20)) + "..."
        }
        return firstLine
    }
    
    // MARK: - Codable Keys
    enum CodingKeys: String, CodingKey {
        case id
        case novelId = "novel_id"
        case body
        case createdAt = "created_at"
    }
}
