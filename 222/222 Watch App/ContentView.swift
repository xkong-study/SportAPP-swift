import SwiftUI
import HealthKit
import AVFoundation
import WatchConnectivity

struct ContentView: View {
    @State private var heartRate = 0
    @State private var timer: Timer?
    @State private var timeRemaining = 60
    @State private var repsPerMinute: [Int] = []
    @State private var averageReps = 0
    private let healthStore = HKHealthStore()
    private let healthManager = HealthManager()
    @State private var audioPlayer: AVAudioPlayer?
    private var workoutSessionManager = WorkoutSessionManager()
    @State private var isDataSendingActive = false // New state

    var body: some View {
        VStack {
            Text("心率: \(heartRate) bpm").font(.title)
            Button("建议举重个数/组") {
                calculateAverageReps()
            }
            Button("开始") {
                isDataSendingActive.toggle() // Toggle data sending state
                if isDataSendingActive {
                    startHeartRateStreaming()
                    startSendingRepsPerMinuteData()
//                    addMockHeartRateData()
                }
            }
            .padding()
            .background(isDataSendingActive ? Color.green : Color.blue) // Change color based on state
            .foregroundColor(.white)
            .cornerRadius(10)

            Button("结束") {
                stopDataSending() // Stop data sending and
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .onAppear {
        requestHealthKitPermission()
        preparePlayer()
        workoutSessionManager.onRepsCounted = { repsCount in
            self.repsPerMinute.append(repsCount)
        }
        workoutSessionManager.useMockData = false
        workoutSessionManager.startSession()
    }
}

    private func stopDataSending() {
            isDataSendingActive = false
            timer?.invalidate() // Invalidate timer
            audioPlayer?.stop() // Stop audio player
            audioPlayer?.currentTime = 0
        }

    
    private func calculateAverageReps() {
        if !repsPerMinute.isEmpty {
            averageReps = repsPerMinute.reduce(0, +) / repsPerMinute.count
            sendAverageRepsRate(averageReps: averageReps)
        }
    }
    
    private func addMockHeartRateData() {
            healthManager.addMockHeartRateData(heartRateValue: 140) { success, error in
                if success {
                    print("Mock data added successfully.")
//                    startHeartRateStreaming()
                } else {
                    print("Failed to add mock data: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    
    func sendHeartRate(heartRate: Int) {
        print("Sending heart rate: \(heartRate)")
        let manager = WatchConnectivityManager.shared
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = manager
            session.activate()
        }

        if WCSession.default.isReachable {
                let message = ["heartRate": heartRate]
                WCSession.default.sendMessage(message, replyHandler: { response in
                    print("Heart rate sent successfully with response: \(response)")
                }, errorHandler: { error in
                    print("Error sending heart rate: \(error.localizedDescription)")
                })
                print("WCSession is reachable")
            } else {
                print("WCSession is not reachable")
            }
    }
    
    func startSendingRepsPerMinuteData() {
        // 这里假设 workoutSessionManager.onRepsCounted 已经在某处设置
        workoutSessionManager.onRepsCounted = { repsCount in
            self.repsPerMinute.append(repsCount)
            self.sendRepsPerMinuteData()
        }
    }


    func sendAverageRepsRate(averageReps: Int) {
        print("Sending average reps: \(averageReps)")
        
        // Ensure WCSession is supported and is already activated
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else {
            print("WCSession is not supported or not activated")
            return
        }

        // Check if the session is reachable before sending the message
        if WCSession.default.isReachable {
            let message = ["averageReps": averageReps]
            WCSession.default.sendMessage(message, replyHandler: { response in
                print("Average reps sent successfully with response: \(response)")
            }, errorHandler: { error in
                print("Error sending average reps: \(error.localizedDescription)")
            })
            print("WCSession is reachable")
        } else {
            print("WCSession is not reachable")
        }
    }

    func sendRepsPerMinuteData() {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else {
            print("WCSession is not supported or not activated")
            return
        }

        if WCSession.default.isReachable {
            let message = ["repsPerMinute": repsPerMinute]
            WCSession.default.sendMessage(message, replyHandler: { response in
                print("Reps per minute data sent successfully with response: \(response)")
            }, errorHandler: { error in
                print("Error sending reps per minute data: \(error.localizedDescription)")
            })
            print("WCSession is reachable")
        } else {
            print("WCSession is not reachable")
        }
    }

    
    func requestHealthKitPermission() {
        healthManager.authorizeHealthKit { authorized, error in
            if authorized {
                print("HealthKit authorization granted.")
            } else {
                print("HealthKit authorization denied.")
                if let error = error {
                    print("HealthKit authorization error: \(error.localizedDescription)")
                }
            }
        }
    }

    func startHeartRateStreaming() {
        // Invalidate existing timer if any
        timer?.invalidate()

        // Start the timer to fetch heart rate data every second
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Only continue if data sending is active
            if self.isDataSendingActive {
                // Fetch the latest heart rate data
                self.healthManager.fetchLatestHeartRateSample { (heartRateValue, error) in
                    if let error = error {
                        print("Error fetching heart rate data: \(error.localizedDescription)")
                        return
                    }

                    DispatchQueue.main.async {
                        self.heartRate = Int(heartRateValue)
                        self.sendHeartRate(heartRate: self.heartRate)
                        print("心率: \(self.heartRate) bpm")

                        // If heart rate is above a certain threshold, play music
                        if self.heartRate >= 135 {
                            self.checkConditionsAndPlayMusic()
                        }
                    }
                }
            } else {
                // Stop the timer and music when data sending is not active
                self.timer?.invalidate()
                self.timer = nil
                DispatchQueue.main.async {
                    self.audioPlayer?.stop()
                    self.audioPlayer?.currentTime = 0
                }
            }
        }
        self.timer?.fire() // Start the timer immediately
    }


    
    func preparePlayer() {
        guard let url = Bundle.main.url(forResource: "经济舱", withExtension: "mp3") else {
            print("未能找到音乐文件。")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            self.audioPlayer = player
        } catch {
            print("音乐播放器初始化失败: \(error)")
        }
    }

    func checkConditionsAndPlayMusic() {
        if self.audioPlayer?.isPlaying == false {
            self.audioPlayer?.play()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
