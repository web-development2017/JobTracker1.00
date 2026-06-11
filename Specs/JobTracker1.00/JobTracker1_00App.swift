//
//  JobTracker1_00App.swift
//  JobTracker1.00
//
//  Created by Rich Taylor on 06/06/2026.
//

import SwiftUI

@main
struct JobTracker1_00App: App {
    // 1. Observe our AuthManager state changes
    @State private var authManager = AuthManager.shared

    var body: some Scene {
        WindowGroup {
            // 2. Dynamically switch views based on authentication status
            if authManager.isAuthenticated {
                ContentView()
            } else {
                LoginView()
            }
        }
    }
}
