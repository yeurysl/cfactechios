//
//  LoginManager.swift
//  cfactech
//
//  Created by Yeurys Lora on 2/10/25.
//


import SwiftUI
import Foundation
import Combine
import JWTDecode  // Import JWTDecode

class LoginManager: ObservableObject {
    @Published var isLoggedIn: Bool = false

    func login(username: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        let loginURL = "https://cfautocare.biz/api/login"
        guard let url = URL(string: loginURL) else {
            completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL."])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ["username": username, "password": password]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "No data received."])))
                return
            }

            // Debug: Print the raw response string
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Login response raw data: \(rawResponse)")
            }

            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let token = jsonResponse["token"] as? String {
                    
                    // Save the JWT token
                    KeychainManager.shared.save(key: "userToken", value: token)
                    
                    // Decode the token to extract the user ID
                    do {
                        let jwt = try decode(jwt: token)
                        if let userId = jwt.subject {
                            // Save the user ID with a separate key
                            KeychainManager.shared.save(key: "userId", value: userId)
                            print("Decoded userId: \(userId)")
                        } else {
                            print("User ID (sub) not found in token.")
                        }
                    } catch {
                        print("Error decoding JWT: \(error)")
                    }
                    
                    DispatchQueue.main.async {
                        self.isLoggedIn = true
                    }
                    completion(.success(token))
                } else {
                    completion(.failure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response format."])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // Get the stored token from the Keychain
    func getToken() -> String? {
        return KeychainManager.shared.retrieve(key: "userToken")
    }

    func logout() {
        KeychainManager.shared.delete(key: "userToken")
        KeychainManager.shared.delete(key: "userId")  // Also delete the stored userId
        isLoggedIn = false
    }
}
