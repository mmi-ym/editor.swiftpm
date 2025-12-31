import SwiftUI

struct WritingCalendarView: View {
    @ObservedObject private var dataManager = DataManager.shared
    let novel: Novel
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var logToEdit: WriteLog?
    @State private var logToDelete: WriteLog?
    @Environment(\.dismiss) var dismiss
    
    // 選択された日のログ一覧
    private var logsForSelectedDate: [WriteLog] {
        dataManager.writeLogs.filter {
            $0.novelId == novel.id && Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }
    }
    
    // 現在の月の全ログ
    private var logsForCurrentMonth: [WriteLog] {
        let startOfMonth = Calendar.current.startOfMonth(for: currentMonth)
        let endOfMonth = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        return dataManager.writeLogs.filter {
            $0.novelId == novel.id && $0.date >= startOfMonth && $0.date <= endOfMonth
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 上半分：カレンダー
                VStack(spacing: 0) {
                    monthNavigationBar
                    calendarGrid
                }
                .background(Color(UIColor.systemBackground))
                
                Divider()
                
                // 下半分：選択日の詳細
                selectedDateDetails
                
                // フッター：月間・年間集計
                statisticsFooter
            }
            .navigationTitle("\(novel.title) 執筆記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("作品一覧")
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
                AddWriteLogSheet(novel: novel, selectedDate: selectedDate, isPresented: $showingAddSheet)
            }
            .sheet(isPresented: $showingEditSheet) {
                if let log = logToEdit {
                    EditWriteLogSheet(novel: novel, log: log, isPresented: $showingEditSheet)
                }
            }
            .alert("執筆記録を削除", isPresented: $showingDeleteAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("削除", role: .destructive) {
                    if let log = logToDelete {
                        deleteLog(log)
                    }
                }
            } message: {
                Text("この執筆記録を削除します。この操作は取り消せません。")
            }
        }
    }
    
    // MARK: - Statistics Footer
    private var statisticsFooter: some View {
        HStack(spacing: 0) {
            // 月間合計
            VStack(alignment: .leading, spacing: 4) {
                Text("今月の執筆")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatNumber(monthlyTotal) + "文字")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            
            Divider()
            
            // 年間合計
            VStack(alignment: .leading, spacing: 4) {
                Text("今年の執筆")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatNumber(yearlyTotal) + "文字")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - Monthly and Yearly Totals
    private var monthlyTotal: Int {
        let startOfMonth = Calendar.current.startOfMonth(for: currentMonth)
        let endOfMonth = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        return dataManager.writeLogs
            .filter {
                $0.novelId == novel.id &&
                $0.date >= startOfMonth &&
                $0.date <= endOfMonth
            }
            .reduce(0) { $0 + $1.writeCount }
    }
    
    private var yearlyTotal: Int {
        let year = Calendar.current.component(.year, from: currentMonth)
        
        // 1月1日から当月末日まで
        let startOfYear = Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endOfCurrentMonth = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), 
                                              to: Calendar.current.startOfMonth(for: currentMonth))!
        
        return dataManager.writeLogs
            .filter {
                $0.novelId == novel.id &&
                $0.date >= startOfYear &&
                $0.date <= endOfCurrentMonth
            }
            .reduce(0) { $0 + $1.writeCount }
    }
    
    // MARK: - Month Navigation Bar
    private var monthNavigationBar: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
            }
            
            Spacer()
            
            Text(monthYearString)
                .font(.headline)
            
            Spacer()
            
            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .padding()
    }
    
    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        VStack(spacing: 0) {
            // 曜日ヘッダー
            HStack(spacing: 0) {
                ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(day == "日" ? .red : day == "土" ? .blue : .secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 4)
            
            // カレンダーグリッド
            let days = generateCalendarDays()
            let rows = days.chunked(into: 7)
            
            ForEach(Array(rows.enumerated()), id: \.offset) { _, week in
                HStack(spacing: 0) {
                    ForEach(week, id: \.date) { dayData in
                        CalendarDayCell(
                            dayData: dayData,
                            isSelected: Calendar.current.isDate(dayData.date, inSameDayAs: selectedDate),
                            isToday: Calendar.current.isDateInToday(dayData.date)
                        )
                        .onTapGesture {
                            if dayData.isCurrentMonth {
                                selectedDate = dayData.date
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Selected Date Details
    private var selectedDateDetails: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ヘッダー
            HStack {
                Text(selectedDateString)
                    .font(.headline)
                    .padding()
                
                Spacer()
                
                if !logsForSelectedDate.isEmpty {
                    let totalChars = logsForSelectedDate.reduce(0) { $0 + $1.writeCount }
                    Text("\(formatNumber(totalChars))文字")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
            
            // ログリスト
            if logsForSelectedDate.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "Calendar.current.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("この日の執筆記録はありません")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(logsForSelectedDate) { log in
                        WriteLogRow(log: log)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    logToDelete = log
                                    showingDeleteAlert = true
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                                
                                Button {
                                    logToEdit = log
                                    showingEditSheet = true
                                } label: {
                                    Label("編集", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    // MARK: - Helper Methods
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: currentMonth)
    }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日（E）"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: selectedDate)
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func generateCalendarDays() -> [CalendarDayData] {
        var days: [CalendarDayData] = []
        let startOfMonth = Calendar.current.startOfMonth(for: currentMonth)
        let numberOfDays = Calendar.current.numberOfDaysInMonth(for: currentMonth)
        let firstWeekday = Calendar.current.firstWeekdayOfMonth(for: currentMonth)
        
        // 前月の日付で埋める
        for _ in 1..<firstWeekday {
            days.append(CalendarDayData(date: Date(), day: 0, isCurrentMonth: false, writeCount: 0))
        }
        
        // 当月の日付
        for day in 1...numberOfDays {
            if let date = Calendar.current.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                let writeCount = logsForCurrentMonth
                    .filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
                    .reduce(0) { $0 + $1.writeCount }
                
                days.append(CalendarDayData(date: date, day: day, isCurrentMonth: true, writeCount: writeCount))
            }
        }
        
        return days
    }
    
    private func deleteLog(_ log: WriteLog) {
        withAnimation {
            dataManager.deleteWriteLog(novelId: log.novelId, date: log.date)
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "0"
    }
}

// MARK: - Calendar Day Data
struct CalendarDayData {
    let date: Date
    let day: Int
    let isCurrentMonth: Bool
    let writeCount: Int
}

// MARK: - Calendar Day Cell
struct CalendarDayCell: View {
    let dayData: CalendarDayData
    let isSelected: Bool
    let isToday: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayData.day > 0 ? "\(dayData.day)" : "")
                .font(.system(size: 14))
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(dayData.isCurrentMonth ? .primary : .clear)
            
            if dayData.writeCount > 0 {
                Text("\(dayData.writeCount)")
                    .font(.system(size: 10))
                    .foregroundColor(.blue)
            } else {
                Text(" ")
                    .font(.system(size: 10))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.2) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isToday ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Write Log Row
struct WriteLogRow: View {
    let log: WriteLog
    @ObservedObject private var dataManager = DataManager.shared
    
    private var novel: Novel? {
        dataManager.novels.first { $0.id == log.novelId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 小作品タイトル
            if let novel = novel {
                Text(novel.title)
                    .font(.system(size: 18, weight: .bold))
                    .padding(.bottom, 4)
            }
            
            HStack {
                Text("執筆文字数")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(log.formattedWriteCount)
                    .font(.headline)
            }
            
            HStack {
                Text("総文字数")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(log.formattedTotalCount)
                    .font(.subheadline)
            }
            
            HStack {
                Text("作業時間")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(log.formattedWorkingTime)
                    .font(.subheadline)
            }
            
            if !log.memo.isEmpty {
                Text(log.memo)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Array Extension
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Preview
#Preview {
    WritingCalendarView(novel: Novel(
        id: 1,
        genreId: 1,
        title: "魔法学園の冒険"
    ))
}
