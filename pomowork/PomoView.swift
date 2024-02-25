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
    let breakCounts = ["1回","2回","3回","4回","5回"]
    
    @State private var selectedWorkDuration = "10秒"
    @State private var selectedBreakDuration = "10秒"
    @State private var selectedBreakCount = "1回"
    
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
    
    @State private var selectworktime = false
    @State private var onAppeared = false
    @State private var selectbreaktime = false
    @State private var selectbreakcount = false
    @State private var strippedBreakCount = 0
    
    
    var body: some View {
        NavigationView{
            ZStack {
                VStack {
                    Text("作業時間")
                    HStack {
                        Button(action: {
                            selectworktime = true
                        }) {
                            Text(selectedWorkDuration)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        Text(isWorkTimerRunning ? "作業中" : selectedWorkDuration)
                            .foregroundColor(.gray)
                    }
                    Text("休憩時間")
                    HStack {
                        Button(action: {
                            selectbreaktime = true
                        }){
                            Text(selectedBreakDuration)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        Text(isBreakTimerRunning ? "休憩中" : selectedBreakDuration)
                            .foregroundColor(.gray)
                    }
                    
                    Text("休憩回数")
                    HStack {
                        Button(action: {
                            selectbreakcount = true
                        }){
                            Text(selectedBreakCount)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        if breakcount_sw {
                            Text("休憩回数: \(breakcount)回")
                                .foregroundColor(.gray)
                        } else {
                            Text("\(selectedBreakCount)")
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
                
                .sheet(isPresented: $selectworktime) {
                    VStack {
                        SelectPicker(selectIndex: $selectedWorkDuration,
                                     isShowing: $selectworktime,
                                     elements: workDurations)
                        .presentationDetents([.height(250)])
                        
                    }
                }
                .sheet(isPresented: $selectbreaktime){
                    VStack{
                        SelectPicker(selectIndex: $selectedBreakDuration,
                                     isShowing: $selectbreaktime,
                                     elements: breakDurations)
                        .presentationDetents([.height(250)])
                    }
                }
                .sheet(isPresented: $selectbreakcount){
                    VStack{
                        SelectPicker(selectIndex: $selectedBreakCount,
                                     isShowing: $selectbreakcount,
                                     elements: breakCounts)
                        .presentationDetents([.height(250)])
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                onAppeared = true
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
                strippedBreakCount = Int(selectedBreakCount.dropLast()) ?? 1
                
                if strippedBreakCount == breakcount {
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
        selectedBreakCount = "1回"
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

struct SelectPicker: View {
    static let viewHeight: CGFloat = 200
    @Binding var selectIndex: String
    @Binding var isShowing: Bool
    var elements: [String]
    
    var body: some View {
        VStack {
            VStack {
                Rectangle().fill(Color(UIColor.systemGray4)).frame(height: 1)
                
                Spacer().frame(height: 10)
                
                Button(action: {
                    self.isShowing = false
                }) {
                    HStack {
                        Spacer()
                        
                        Text("完了")
                            .font(.headline)
                        
                        Spacer().frame(width: 20)
                    }
                }
                Spacer().frame(height: 10)
            }
            .background(Color(UIColor.systemGray6))
            Picker(selection: $selectIndex, label: Text("")) {
                ForEach(elements, id: \.self) { element in
                    Text(element)
                }
            }
            .pickerStyle(.wheel)
            .background(Color(UIColor.systemGray4))
            .labelsHidden()
        }
    }
}

struct PomoView_Previews: PreviewProvider {
    static var previews: some View {
        PomoView()
    }
}
