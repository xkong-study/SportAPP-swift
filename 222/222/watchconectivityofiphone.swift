//
//  watchconectivityofiphone.swift
//  222
//
//  Created by チョ・ゴケン on 2023/10/22.
//

import WatchConnectivity

class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    var onHeartRateUpdate: ((Int) -> Void)?
    var onAverageRepsUpdate: ((Int) -> Void)?
    var onRepsPerMinuteUpdate: (([Int]) -> Void)? // 新增的闭包属性
    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    // Required WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Implement your code here if needed
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        // Implement your code here if needed
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // Implement your code here if needed
        // This is a good place to reactivate the session if it's been deactivated.
        session.activate()
    }

    // Your existing method for receiving messages
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if let receivedHeartRate = message["heartRate"] as? Int {
            onHeartRateUpdate?(receivedHeartRate)
            print("Received heart rate: \(receivedHeartRate)")
            replyHandler(["Response": "Heart rate received"])
        } else if let receivedAverageReps = message["averageReps"] as? Int {
            onAverageRepsUpdate?(receivedAverageReps)
            print("Received average reps: \(receivedAverageReps)")
            replyHandler(["Response": "Average reps received"])
        } else if let receivedRepsPerMinute = message["repsPerMinute"] as? [Int] {
            onRepsPerMinuteUpdate?(receivedRepsPerMinute)
            print("Received reps per minute: \(receivedRepsPerMinute)")
            replyHandler(["Response": "Reps per minute received"])
        } else {
            print("Expected data not found in the message")
            replyHandler(["Error": "Invalid message"])
        }
    }

}


