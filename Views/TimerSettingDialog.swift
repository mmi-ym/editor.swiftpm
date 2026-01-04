import SwiftUI

struct TimerSettingDialog: View {
    @ObservedObject var timer: SimpleTimer
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("タイマー時間")
                .font(.headline)
            
            HStack(spacing: 12) {
                Stepper(value: $timer.minutes, in: 1...99) {
                    Text("\(timer.minutes)分")
                        .frame(width: 60, alignment: .leading)
                }
                .onChange(of: timer.minutes) { oldValue, newValue in
                    timer.setMinutes(newValue)
                }
            }
            
            HStack(spacing: 12) {
                Button("キャンセル") {
                    isPresented = false
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(8)
                
                Button("開始") {
                    timer.start()
                    isPresented = false
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(20)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .padding(20)
    }
}

#Preview {
    @State var timer = SimpleTimer()
    @State var isPresented = true
    
    return ZStack {
        Color.black.opacity(0.3).ignoresSafeArea()
        TimerSettingDialog(timer: timer, isPresented: $isPresented)
    }
}
