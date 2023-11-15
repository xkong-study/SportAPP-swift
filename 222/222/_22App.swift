//
//  _22App.swift
//  222
//
//  Created by チョ・ゴケン on 2023/10/22.
//

import SwiftUI

@main
struct _22App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(HeartRateManager.shared)
        }
    }
}
