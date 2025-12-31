import Foundation

/// 執筆ログモデル
struct WriteLog: Identifiable, Codable, Hashable {
    var id: String { "\(date.timeIntervalSince1970)-\(novelId)" }  // 日付とnovelIdの組み合わせで一意性を保証
    var date: Date
    var novelId: Int
    var writeCount: Int  // その日に書いた文字数
    var totalCount: Int  // 総文字数
    var workingTime: Int  // 作業時間（分）
    var memo: String
    
    /// 新規作成用イニシャライザ
    init(
        date: Date = Date(),
        novelId: Int,
        writeCount: Int = 0,
        totalCount: Int = 0,
        workingTime: Int = 0,
        memo: String = ""
    ) {
        self.date = date
        self.novelId = novelId
        self.writeCount = writeCount
        self.totalCount = totalCount
        self.workingTime = workingTime
        self.memo = memo
    }
    
    /// 日付の表示用フォーマット（yyyy/MM/dd）
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    /// 日付の表示用フォーマット（短縮版：MM/dd）
    var shortFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    /// 年月日のコンポーネントを取得
    var dateComponents: DateComponents {
        Calendar.current.dateComponents([.year, .month, .day], from: date)
    }
    
    /// 日付のみを比較（時刻を無視）
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: other)
    }
    
    /// 執筆文字数の表示用フォーマット
    var formattedWriteCount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return (formatter.string(from: NSNumber(value: writeCount)) ?? "0") + "文字"
    }
    
    /// 総文字数の表示用フォーマット
    var formattedTotalCount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return (formatter.string(from: NSNumber(value: totalCount)) ?? "0") + "文字"
    }
    
    /// 作業時間の表示用フォーマット（HH:MM）
    var formattedWorkingTime: String {
        let hours = workingTime / 60
        let minutes = workingTime % 60
        return String(format: "%02d:%02d", hours, minutes)
    }
    
    // MARK: - Codable Keys
    enum CodingKeys: String, CodingKey {
        case date
        case novelId = "novel_id"
        case writeCount = "write_count"
        case totalCount = "total_count"
        case workingTime = "working_time"
        case memo
    }
}

// MARK: - Calendar Helper
extension Calendar {
    /// 指定した月の日数を取得
    func numberOfDaysInMonth(for date: Date) -> Int {
        return range(of: .day, in: .month, for: date)?.count ?? 30
    }
    
    /// 指定した月の最初の日を取得
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
    
    /// 指定した月の最初の日が何曜日か取得（1=日曜日、7=土曜日）
    func firstWeekdayOfMonth(for date: Date) -> Int {
        let startOfMonth = self.startOfMonth(for: date)
        return component(.weekday, from: startOfMonth)
    }
}
