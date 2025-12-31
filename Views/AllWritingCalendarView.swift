import SwiftUI

/// 全作品の執筆記録画面
struct AllWritingCalendarView: View {
    @ObservedObject private var dataManager = DataManager.shared
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var logToEdit: WriteLog?
    @State private var logToDelete: WriteLog?
    @Environment(\.dismiss) var dismiss
    
    // 選択された日の全ログ
    private var logsForSelectedDate: [WriteLog] {
        dataManager.writeLogs.filter {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }
    }
    
    // 現在の月の全ログ
    private var logsForCurrentMonth: [WriteLog] {
        let startOfMonth = Calendar.current.startOfMonth(for: currentMonth)
        let endOfMonth = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        return dataManager.writeLogs.filter {
            $0.date >= startOfMonth && $0.date <= endOfMonth
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
            .navigationTitle("執筆記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("ジャンル一覧")
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
                AddWriteLogSheetForAll(selectedDate: selectedDate, isPresented: $showingAddSheet)
            }
            .sheet(isPresented: $showingEditSheet) {
                if let log = logToEdit {
                    EditWriteLogSheetForAll(log: log, isPresented: $showingEditSheet)
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
    
    // MARK: - Month Navigation Bar
    private var monthNavigationBar: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text(monthYearString(from: currentMonth))
                .font(.headline)
            
            Spacer()
            
            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
    
    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        let daysInMonth = getDaysInMonth(for: currentMonth)
        let firstWeekday = getFirstWeekday(for: currentMonth)
        
        return VStack(spacing: 8) {
            // 曜日ヘッダー
            HStack(spacing: 0) {
                ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(day == "日" ? .red : day == "土" ? .blue : .primary)
                }
            }
            .padding(.horizontal)
            
            // カレンダーグリッド
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                // 空白セル
                ForEach(0..<firstWeekday, id: \.self) { _ in
                    Color.clear
                        .frame(height: 60)
                }
                
                // 日付セル
                ForEach(1...daysInMonth, id: \.self) { day in
                    let date = getDate(year: Calendar.current.component(.year, from: currentMonth),
                                      month: Calendar.current.component(.month, from: currentMonth),
                                      day: day)
                    
                    DayCell(
                        day: day,
                        date: date,
                        writeCount: getTotalWriteCount(for: date),
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        isToday: Calendar.current.isDateInToday(date)
                    )
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // MARK: - Selected Date Details
    private var selectedDateDetails: some View {
        VStack(spacing: 0) {
            if logsForSelectedDate.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("この日の記録はありません")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(logsForSelectedDate) { log in
                    if let novel = dataManager.novels.first(where: { $0.id == log.novelId }) {
                        WriteLogRowForAll(log: log, novel: novel)
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
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    // MARK: - Statistics Footer
    private var statisticsFooter: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("今月の執筆")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(formatNumber(getMonthlyTotal()))文字")
                    .font(.headline)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("今年の執筆")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(formatNumber(getYearlyTotal()))文字")
                    .font(.headline)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - Helper Functions
    private func changeMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }
    
    private func getDaysInMonth(for date: Date) -> Int {
        let range = Calendar.current.range(of: .day, in: .month, for: date)!
        return range.count
    }
    
    private func getFirstWeekday(for date: Date) -> Int {
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        let firstDay = Calendar.current.date(from: components)!
        return Calendar.current.component(.weekday, from: firstDay) - 1
    }
    
    private func getDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)!
    }
    
    private func getTotalWriteCount(for date: Date) -> Int {
        logsForCurrentMonth
            .filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .reduce(0) { $0 + $1.writeCount }
    }
    
    private func getMonthlyTotal() -> Int {
        logsForCurrentMonth.reduce(0) { $0 + $1.writeCount }
    }
    
    private func getYearlyTotal() -> Int {
        let year = Calendar.current.component(.year, from: currentMonth)
        let startOfYear = Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endOfMonth = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1),
                                                to: Calendar.current.startOfMonth(for: currentMonth))!
        
        return dataManager.writeLogs
            .filter { $0.date >= startOfYear && $0.date <= endOfMonth }
            .reduce(0) { $0 + $1.writeCount }
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "0"
    }
    
    private func deleteLog(_ log: WriteLog) {
        dataManager.deleteWriteLog(novelId: log.novelId, date: log.date)
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let day: Int
    let date: Date
    let writeCount: Int
    let isSelected: Bool
    let isToday: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(day)")
                .font(.system(size: 16))
                .foregroundColor(isSelected ? .white : .primary)
            
            if writeCount > 0 {
                Text("\(writeCount)")
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .white : .secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(isSelected ? Color.blue : Color.clear)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isToday ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Write Log Row For All
struct WriteLogRowForAll: View {
    let log: WriteLog
    let novel: Novel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(novel.title)
                .font(.headline)
            
            HStack {
                Label("\(log.writeCount)文字", systemImage: "pencil")
                Spacer()
                if log.totalCount > 0 {
                    Label("総\(log.totalCount)文字", systemImage: "doc.text")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            if log.workingTime > 0 {
                Label(log.formattedWorkingTime, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !log.memo.isEmpty {
                Text(log.memo)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Add Write Log Sheet For All
struct AddWriteLogSheetForAll: View {
    @ObservedObject private var dataManager = DataManager.shared
    let selectedDate: Date
    @Binding var isPresented: Bool
    
    @State private var selectedNovel: Novel?
    @State private var writeCount: String = ""
    @State private var totalCount: String = ""
    @State private var workingHours: String = ""
    @State private var workingMinutes: String = ""
    @State private var memo: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("作品") {
                    Picker("作品を選択", selection: $selectedNovel) {
                        Text("選択してください").tag(nil as Novel?)
                        ForEach(dataManager.novels) { novel in
                            Text(novel.title).tag(novel as Novel?)
                        }
                    }
                }
                
                Section("執筆文字数") {
                    TextField("執筆文字数", text: $writeCount)
                        .keyboardType(.numberPad)
                }
                
                Section("総文字数") {
                    TextField("総文字数", text: $totalCount)
                        .keyboardType(.numberPad)
                }
                
                Section("作業時間") {
                    HStack {
                        TextField("時間", text: $workingHours)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                        Text("時間")
                        
                        TextField("分", text: $workingMinutes)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                        Text("分")
                    }
                }
                
                Section("メモ") {
                    TextEditor(text: $memo)
                        .frame(height: 100)
                }
            }
            .navigationTitle("執筆記録を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveLog()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private var canSave: Bool {
        selectedNovel != nil && !writeCount.isEmpty && Int(writeCount) != nil
    }
    
    private func saveLog() {
        guard let novel = selectedNovel,
              let writeCountInt = Int(writeCount) else { return }
        
        let totalCountInt = Int(totalCount) ?? 0
        let hours = Int(workingHours) ?? 0
        let minutes = Int(workingMinutes) ?? 0
        let workingTimeMinutes = hours * 60 + minutes
        
        dataManager.addOrUpdateWriteLog(
            novelId: novel.id,
            date: selectedDate,
            writeCount: writeCountInt,
            totalCount: totalCountInt,
            workingTime: workingTimeMinutes,
            memo: memo
        )
        
        isPresented = false
    }
}

// MARK: - Edit Write Log Sheet For All
struct EditWriteLogSheetForAll: View {
    @ObservedObject private var dataManager = DataManager.shared
    let log: WriteLog
    @Binding var isPresented: Bool
    
    @State private var writeCount: String = ""
    @State private var totalCount: String = ""
    @State private var workingHours: String = ""
    @State private var workingMinutes: String = ""
    @State private var memo: String = ""
    
    init(log: WriteLog, isPresented: Binding<Bool>) {
        self.log = log
        self._isPresented = isPresented
        self._writeCount = State(initialValue: String(log.writeCount))
        self._totalCount = State(initialValue: String(log.totalCount))
        let hours = log.workingTime / 60
        let minutes = log.workingTime % 60
        self._workingHours = State(initialValue: hours > 0 ? String(hours) : "")
        self._workingMinutes = State(initialValue: minutes > 0 ? String(minutes) : "")
        self._memo = State(initialValue: log.memo)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("執筆文字数") {
                    TextField("執筆文字数", text: $writeCount)
                        .keyboardType(.numberPad)
                }
                
                Section("総文字数") {
                    TextField("総文字数", text: $totalCount)
                        .keyboardType(.numberPad)
                }
                
                Section("作業時間") {
                    HStack {
                        TextField("時間", text: $workingHours)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                        Text("時間")
                        
                        TextField("分", text: $workingMinutes)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                        Text("分")
                    }
                }
                
                Section("メモ") {
                    TextEditor(text: $memo)
                        .frame(height: 100)
                }
            }
            .navigationTitle("執筆記録を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        updateLog()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private var canSave: Bool {
        !writeCount.isEmpty && Int(writeCount) != nil
    }
    
    private func updateLog() {
        guard let writeCountInt = Int(writeCount) else { return }
        
        let totalCountInt = Int(totalCount) ?? 0
        let hours = Int(workingHours) ?? 0
        let minutes = Int(workingMinutes) ?? 0
        let workingTimeMinutes = hours * 60 + minutes
        
        dataManager.addOrUpdateWriteLog(
            novelId: log.novelId,
            date: log.date,
            writeCount: writeCountInt,
            totalCount: totalCountInt,
            workingTime: workingTimeMinutes,
            memo: memo
        )
        
        isPresented = false
    }
}
