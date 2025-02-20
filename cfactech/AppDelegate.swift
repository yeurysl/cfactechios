//
//  AppDelegate.swift
//  cfactech
//
//  Created by Yeurys Lora on 2/17/25.
//




import UIKit
import UserNotifications
import SwiftUI
import Combine
import Foundation




class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    // Called when the app launches.
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        print(">> Requesting notification authorization...")
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error.localizedDescription)")
                return
            }
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else {
                print("Notification permission was not granted.")
            }
        }
        return true
    }
    
    // Called when the device successfully registers for remote notifications.
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print(">> didRegisterForRemoteNotificationsWithDeviceToken called")
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        
        // Optionally, store the token in the Keychain.
        KeychainManager.shared.save(key: "deviceToken", value: token)
        
        // If the user is already logged in, send the token to your server.
        if let userId = AuthManager.shared.getUserId() {
            // Updated function call with userId and token.
            sendDeviceTokenToServer(userId: userId, deviceToken: token)
        }
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Received notification in foreground: \(notification.request.content.userInfo)")
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("User tapped on notification: \(response.notification.request.content.userInfo)")
        completionHandler()
    }
    
    // Updated function to send the device token along with the user ID.
    func sendDeviceTokenToServer(userId: String, deviceToken: String) {
        guard let url = URL(string: "https://cfautocare.biz/api/tech/register_device_token") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "device_token": deviceToken,
            "user_id": userId  // Use the actual user identifier.
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            request.httpBody = jsonData
            print("Sending device token payload: \(payload)")
        } catch {
            print("Error serializing JSON: \(error.localizedDescription)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending device token: \(error.localizedDescription)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("Server responded with status code: \(httpResponse.statusCode)")
            }
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Response from server: \(responseString)")
            }
        }
        task.resume()
    }
}
