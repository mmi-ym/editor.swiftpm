import Foundation

/// 小作品設定モデル
struct NovelSettings: Identifiable, Codable, Hashable {
    var id: Int
    var novelId: Int
    var attribute: AttributeType
    var title: String  // 設定のタイトル
    var body: String
    
    /// 設定の属性タイプ
    enum AttributeType: Int, Codable, CaseIterable {
        case character = 1  // キャラ設定
        case plot = 2       // プロット
        case terminology = 3  // 専門用語
        case other = 4      // その他
        
        var displayName: String {
            switch self {
            case .character:
                return "キャラ設定"
            case .plot:
                return "プロット"
            case .terminology:
                return "専門用語"
            case .other:
                return "その他"
            }
        }
        
        var icon: String {
            switch self {
            case .character:
                return "person.circle"
            case .plot:
                return "list.bullet.rectangle"
            case .terminology:
                return "book.closed"
            case .other:
                return "doc.text"
            }
        }
    }
    
    /// 新規作成用イニシャライザ
    init(
        id: Int = 0,
        novelId: Int,
        attribute: AttributeType = .character,
        title: String = "",
        body: String = ""
    ) {
        self.id = id
        self.novelId = novelId
        self.attribute = attribute
        self.title = title
        self.body = body
    }
    
    /// 表示用のタイトル
    var displayTitle: String {
        if title.isEmpty {
            return attribute.displayName
        }
        return title
    }
    
    /// 本文のプレビュー（最初の30文字）
    var bodyPreview: String {
        let text = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.count > 30 {
            return String(text.prefix(30)) + "..."
        }
        return text.isEmpty ? "内容なし" : text
    }
    
    // MARK: - Codable Keys
    enum CodingKeys: String, CodingKey {
        case id
        case novelId = "novel_id"
        case attribute
        case title
        case body
    }
}
