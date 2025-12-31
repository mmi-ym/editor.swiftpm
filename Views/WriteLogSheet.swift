import SwiftUI

// MARK: - Add Write Log Sheet
struct AddWriteLogSheet: View {
    @StateObject private var dataManager = DataManager.shared
    let novel: Novel
    let selectedDate: Date
    @Binding var isPresented: Bool
    
    @State private var writeCount: String = ""
    @State private var totalCount: String = ""
    @State private var workingHours: String = "00"
    @State private var workingMinutes: String = "00"
    @State private var memo: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("日付") {
                    HStack {
                        Text("記録日")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formattedDate(selectedDate))
                    }
                }
                
                Section("作品") {
                    HStack {
                        Text("作品名")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(novel.title)
                    }
                }
                
                Section("執筆文字数") {
                    TextField("文字数", text: $writeCount)
                        .keyboardType(.numberPad)
                }
                
                Section("総文字数") {
                    TextField("総文字数", text: $totalCount)
                        .keyboardType(.numberPad)
                }
                
                Section("作業時間") {
                    HStack {
                        TextField("00", text: $workingHours)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text(":")
                        TextField("00", text: $workingMinutes)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                        Text("（時:分）")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("メモ") {
                    TextEditor(text: $memo)
                        .frame(height: 100)
                }
            }
            .navigationTitle("執筆記録追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        addLog()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        guard let _ = Int(writeCount), writeCount.count > 0 else { return false }
        return true
    }
    
    private func addLog() {
        let write = Int(writeCount) ?? 0
        let total = Int(totalCount) ?? 0
        let hours = Int(workingHours) ?? 0
        let minutes = Int(workingMinutes) ?? 0
        let workingTimeInMinutes = hours * 60 + minutes
        
        dataManager.addOrUpdateWriteLog(
            novelId: novel.id,
            date: selectedDate,
            writeCount: write,
            totalCount: total,
            workingTime: workingTimeInMinutes,
            memo: memo
        )
        
        isPresented = false
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日（E）"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - Edit Write Log Sheet
struct EditWriteLogSheet: View {
    @StateObject private var dataManager = DataManager.shared
    let novel: Novel
    let log: WriteLog
    @Binding var isPresented: Bool
    
    @State private var writeCount: String = ""
    @State private var totalCount: String = ""
    @State private var workingHours: String = "00"
    @State private var workingMinutes: String = "00"
    @State private var memo: String = ""
    
    init(novel: Novel, log: WriteLog, isPresented: Binding<Bool>) {
        self.novel = novel
        self.log = log
        self._isPresented = isPresented
        
        self._writeCount = State(initialValue: "\(log.writeCount)")
        self._totalCount = State(initialValue: "\(log.totalCount)")
        
        let hours = log.workingTime / 60
        let minutes = log.workingTime % 60
        self._workingHours = State(initialValue: String(format: "%02d", hours))
        self._workingMinutes = State(initialValue: String(format: "%02d", minutes))
        self._memo = State(initialValue: log.memo)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("日付") {
                    HStack {
                        Text("記録日")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formattedDate(log.date))
                    }
                }
                
                Section("作品") {
                    HStack {
                        Text("作品名")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(novel.title)
                    }
                }
                
                Section("執筆文字数") {
                    TextField("文字数", text: $writeCount)
                        .keyboardType(.numberPad)
                }
                
                Section("総文字数") {
                    TextField("総文字数", text: $totalCount)
                        .keyboardType(.numberPad)
                }
                
                Section("作業時間") {
                    HStack {
                        TextField("00", text: $workingHours)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text(":")
                        TextField("00", text: $workingMinutes)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                        Text("（時:分）")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("メモ") {
                    TextEditor(text: $memo)
                        .frame(height: 100)
                }
            }
            .navigationTitle("執筆記録編集")
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
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        guard let _ = Int(writeCount), writeCount.count > 0 else { return false }
        return true
    }
    
    private func updateLog() {
        let write = Int(writeCount) ?? 0
        let total = Int(totalCount) ?? 0
        let hours = Int(workingHours) ?? 0
        let minutes = Int(workingMinutes) ?? 0
        let workingTimeInMinutes = hours * 60 + minutes
        
        dataManager.addOrUpdateWriteLog(
            novelId: novel.id,
            date: log.date,
            writeCount: write,
            totalCount: total,
            workingTime: workingTimeInMinutes,
            memo: memo
        )
        
        isPresented = false
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日（E）"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    AddWriteLogSheet(
        novel: Novel(id: 1, genreId: 1, title: "魔法学園の冒険"),
        selectedDate: Date(),
        isPresented: .constant(true)
    )
}
