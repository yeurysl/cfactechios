

//
//  AuthManager.swift
//  cfacios
//
//  Created by Yeurys Lora on 1/15/25.
//


import Foundation
import Combine
import JWTDecode

class AuthManager {
    static let shared = AuthManager()
    private let tokenKey = "userToken"

    private init() {}

    func saveToken(_ token: String) {
        KeychainManager.shared.save(key: tokenKey, value: token)
    }

    func getToken() -> String? {
        return KeychainManager.shared.retrieve(key: tokenKey)
    }

    func clearToken() {
        KeychainManager.shared.delete(key: tokenKey)
    }
    
    // New: Get the logged in user's ID by decoding the JWT token.
    func getUserId() -> String? {
        guard let token = getToken() else { return nil }
        do {
            let jwt = try decode(jwt: token)
            return jwt.subject  // typically the 'sub' field
        } catch {
            print("Error decoding token: \(error)")
            return nil
        }
    }
}

func loginUser(email: String, password: String) {
    let loginURL = "https://cfautocare.biz/api/login"
    var request = URLRequest(url: URL(string: loginURL)!)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let body: [String: Any] = ["email": email, "password": password]
    
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print("Login failed: \(error?.localizedDescription ?? "Unknown error")")
            return
        }
        
        // Decode the response to extract the token
        let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let token = jsonResponse?["token"] as? String {
            AuthManager.shared.saveToken(token)
            print("Token saved: \(token)")
        }
    }.resume()
}
