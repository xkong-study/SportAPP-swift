//
//  watchconectivity.swift
//  222 Watch App
//
//  Created by チョ・ゴケン on 2023/10/22.
//

import Foundation
import WatchConnectivity

class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager() // Singleton instance
    var heartRate: Int = 0
    
    override init() {
        super.init()
        if WCSession.isSupported() { // Check if the device supports WCSession
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func sendHeartRate(heartRate: Int) {
           if WCSession.default.isReachable {
               let message = ["heartRate": heartRate]
               WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: { (error) in
                   print("Error sending heart rate: \(error.localizedDescription)")
               })
           }
       }
    
    // Function to send heart rate to the paired iPhone
    func updateHeartRateOniPhone(heartRate: Int) {
        // Make sure you are on the activated session before sending a message
        guard WCSession.default.activationState == .activated else {
            print("WCSession is not activated")
            return
        }
        
        // Check if the session is reachable before sending the message
        if WCSession.default.isReachable {
            let message = ["heartRate": heartRate]
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: { error in
                // Handle any errors here
                print("Error sending heart rate: \(error)")
            })
        } else {
            print("WCSession is not reachable")
        }
    }
    
    // WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Handle session activation completion
        if activationState != .activated {
            if let error = error {
                print("WCSession activation failed with error: \(error.localizedDescription)")
            } else {
                print("WCSession not activated but no error returned.")
            }
        }
    }
}
