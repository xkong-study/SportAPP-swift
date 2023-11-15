//
//  ContentView.swift
//  222
//
//  Created by チョ・ゴケン on 2023/10/22.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var heartRateManager: HeartRateManager

    var body: some View {
        VStack {
            Text("心率: \(heartRateManager.heartRate) BPM")
                .font(.title)
            Text("建议平均次数: \(heartRateManager.averageReps)")
                .font(.title)

            // 展示每一分钟的举重次数
            List {
                ForEach(heartRateManager.repsPerMinute.indices, id: \.self) { index in
                    Text("第 \(index + 1) 分钟的举重次数: \(heartRateManager.repsPerMinute[index])")
                }
            }
        }
    }
}
