//
//  cfactechApp.swift
//  cfactech
//
//  Created by Yeurys Lora on 2/10/25.
//

import SwiftUI
import Combine
import Foundation

@main
struct cfactechApp: App {
    @StateObject private var loginManager = LoginManager()
    @StateObject private var techViewModel = TechViewModel() // Create TechViewModel instance

    var body: some Scene {
        WindowGroup {
            if loginManager.isLoggedIn {
                MainView()
                    .environmentObject(loginManager)   // Inject loginManager
                    .environmentObject(techViewModel)  // Inject techViewModel
            } else {
                LoginView()
                    .environmentObject(loginManager)   // Inject loginManager
            }
        }
    }
}
