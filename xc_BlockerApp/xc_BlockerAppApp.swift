//
//  xc_BlockerAppApp.swift
//  xc_BlockerApp
//
//  Created by 🌊 on 05/02/2026.
//

import SwiftUI

@main
struct BlockerAppApp: App {
    @StateObject private var controller = SessionController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(controller)
        }
    }
}
