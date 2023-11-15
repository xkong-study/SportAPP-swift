//
//  ObservableObject.swift
//  222
//
//  Created by チョ・ゴケン on 2023/10/22.
//

import Foundation
//class HeartRateManager: ObservableObject {
//    @Published var heartRate: Int = 0
//    private var watchConnectivityManager: WatchConnectivityManager
//
//    init() {
//        watchConnectivityManager = WatchConnectivityManager()
//        
//        watchConnectivityManager.onHeartRateUpdate = { rate in
//            DispatchQueue.main.async {
//                self.heartRate = rate
//            }
//        }
//    }
//}

class HeartRateManager: ObservableObject {
    static let shared = HeartRateManager()
    @Published var heartRate: Int = 0
    @Published var averageReps: Int = 0
    @Published var repsPerMinute: [Int] = [] // 新增的属性

    private var watchConnectivityManager: WatchConnectivityManager

    private init() {
        watchConnectivityManager = WatchConnectivityManager.shared
        
        watchConnectivityManager.onHeartRateUpdate = { [weak self] rate in
            DispatchQueue.main.async {
                self?.heartRate = rate
            }
        }

        watchConnectivityManager.onAverageRepsUpdate = { [weak self] reps in
            DispatchQueue.main.async {
                self?.averageReps = reps
            }
        }

        // 设置接收每分钟举重次数更新的闭包
        watchConnectivityManager.onRepsPerMinuteUpdate = { [weak self] reps in
            DispatchQueue.main.async {
                self?.repsPerMinute = reps
            }
        }
    }
}
