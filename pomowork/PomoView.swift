import SwiftUI
import AudioToolbox

enum AlertType {
    case workfinish
    case breakfinish
    case cyclefinish
    case resetConfirmation
}

struct PomoView: View {
    let workDurations = ["10秒","1分", "10分", "15分", "20分", "25分", "30分", "35分", "40分", "45分", "50分", "55分", "60分"]
    let breakDurations = ["10秒","1分", "5分", "10分", "15分", "20分", "25分", "30分"]
    let breakCounts = [1,2,3,4,5]
    
    @State private var selectedWorkDuration = "10秒"
    @State private var selectedBreakDuration = "10秒"
    @State private var selectedBreakCount = 1
    
    @State private var remainingSeconds = 0
    @State private var isWorkTimerRunning = false
    @State private var isBreakTimerRunning = false
    @State private var breakcount_sw = false
    @State private var timer: Timer?
    
    @State var showingAlert = false
    @State var alertType: AlertType = .workfinish
    
    @State private var buttonLabel = "作業開始"
    @State private var breakcount = 0
    
    @State private var totalWorkDuration = 0
    @State private var totalBreakDuration = 0
    @State private var totalwork = 0
    @State private var totalbreak = 0
    @State private var totalTime = 0
    
    
    var body: some View {
        NavigationView{
            VStack {
                Text("作業時間")
                HStack {
                    Picker("作業時間", selection: $selectedWorkDuration) {
                        ForEach(workDurations, id: \.self) { duration in
                            Text(duration).tag(duration)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 90)
                    Text(isWorkTimerRunning ? "作業中" : selectedWorkDuration)
                        .foregroundColor(.gray)
                }
                
                Text("休憩時間")
                HStack {
                    Picker("休憩時間", selection: $selectedBreakDuration) {
                        ForEach(breakDurations, id: \.self) { duration in
                            Text(duration).tag(duration)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 90)
                    Text(isBreakTimerRunning ? "休憩中" : selectedBreakDuration)
                        .foregroundColor(.gray)
                }
                
                Text("休憩回数")
                HStack {
                    Picker("休憩回数", selection: $selectedBreakCount) {
                        ForEach(breakCounts, id: \.self) { count in
                            Text("\(count) 回").tag(count)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 90)
                    if breakcount_sw {
                        Text("休憩回数: \(breakcount)")
                            .foregroundColor(.gray)
                    } else {
                        Text("\(selectedBreakCount)回")
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: {
                    if isWorkTimerRunning || isBreakTimerRunning {
                        // タイマーが実行中の場合は何もしない
                    } else if buttonLabel == "作業開始" || buttonLabel == "作業再開" {
                        startWorkTimer(durationString: selectedWorkDuration)
                    } else if buttonLabel == "休憩開始" {
                        startBreakTimer(durationString: selectedBreakDuration)
                    }
                }) {
                    Text(buttonLabel)
                        .padding()
                        .background(Color.cyan)
                        .foregroundColor(.white)
                }
                .disabled(isWorkTimerRunning || isBreakTimerRunning)
                
                Button(action: {
                    showingAlert = true
                    alertType = .resetConfirmation
                }) {
                    Text("リセット")
                        .padding()
                        .background(Color.cyan)
                        .foregroundColor(.white)
                }
                
                if remainingSeconds > 0 {
                    Text("残り時間: \(formattedTime(remainingSeconds))")
                        .padding()
                }
            }
            .alert(isPresented: $showingAlert) {
                switch alertType {
                case .workfinish:
                    AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) {}
                    return Alert(title: Text("作業終了"), message: Text("作業時間が終了しました"), dismissButton: .default(Text("OK")))
                case .breakfinish:
                    AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) {}
                    return Alert(title: Text("休憩終了"), message: Text("休憩時間が終了しました"), dismissButton: .default(Text("OK")))
                case .cyclefinish:
                    AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) {}
                    return Alert(title: Text("サイクルが終了しました"), message: Text("お疲れ様でした\n合計時間: \(formattedTotalTime(totalTime))\n作業時間: \(formattedTotalTime(totalwork))\n休憩時間: \(formattedTotalTime(totalbreak))"), dismissButton: .default(Text("OK")))
                case .resetConfirmation:
                    return Alert(
                        title: Text("リセットしますか？"),
                        primaryButton: .destructive(Text("Yes")) {
                            resetTimer()
                        },
                        secondaryButton: .cancel(Text("No"))
                    )
                }
            }
            .padding()
            .navigationTitle("ポモタイマー")
        }
    }
    
    private func startWorkTimer(durationString: String) {
        var durationInSeconds = 0
        
        if durationString.hasSuffix("秒") {
            durationInSeconds = Int(durationString.dropLast(1)) ?? 0
        } else if durationString.hasSuffix("分") {
            let minutes = Int(durationString.dropLast(1)) ?? 0
            durationInSeconds = minutes * 60
        }
        
        totalWorkDuration += durationInSeconds
        totalwork = totalWorkDuration
        totalTime = totalWorkDuration + totalBreakDuration
        
        remainingSeconds = durationInSeconds
        isWorkTimerRunning = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                timer.invalidate()
                showingAlert = true
                alertType = .workfinish
                buttonLabel = "休憩開始"
                isWorkTimerRunning = false
                
                if selectedBreakCount == breakcount {
                    showingAlert = true
                    alertType = .cyclefinish
                    resetTimer()
                }
            }
        }
    }
    
    private func startBreakTimer(durationString: String) {
        var durationInSeconds = 0
        breakcount_sw = true
        
        if durationString.hasSuffix("秒") {
            durationInSeconds = Int(durationString.dropLast(1)) ?? 0
        } else if durationString.hasSuffix("分") {
            let minutes = Int(durationString.dropLast(1)) ?? 0
            durationInSeconds = minutes * 60
        }
        
        totalBreakDuration += durationInSeconds
        totalbreak = totalBreakDuration
        
        remainingSeconds = durationInSeconds
        isBreakTimerRunning = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                timer.invalidate()
                breakcount += 1
                showingAlert = true
                alertType = .breakfinish
                buttonLabel = "作業再開"
                isBreakTimerRunning = false
            }
        }
    }
    
    private func resetTimer() {
        timer?.invalidate()
        isWorkTimerRunning = false
        isBreakTimerRunning = false
        remainingSeconds = 0
        buttonLabel = "作業開始"
        breakcount = 0
        breakcount_sw = false
        selectedWorkDuration = "10秒"
        selectedBreakDuration = "10秒"
        selectedBreakCount = 1
        totalWorkDuration = 0
        totalBreakDuration = 0
    }
    
    private func formattedTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func formattedTotalTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d時間%02d分%02d秒", hours, minutes, remainingSeconds)
    }
}

#Preview {
    PomoView()
}
