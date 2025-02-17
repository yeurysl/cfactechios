//
//  TechViewModel.swift
//  cfactech
//
//  Created by Yeurys Lora on 2/11/25.
//


import Combine
import Foundation






struct RemainingTimeResponse: Codable {
    let remainingTime: TimeComponents
    let currentTimeUtc: String
    let scheduledTimeUtc: String
    
    enum CodingKeys: String, CodingKey {
        case remainingTime = "remaining_time"
        case currentTimeUtc = "current_time_utc"
        case scheduledTimeUtc = "scheduled_time_utc"
    }
    
    struct TimeComponents: Codable {
        let hoursRemaining: Int?
        let minutesRemaining: Int?
        
        enum CodingKeys: String, CodingKey {
            case hoursRemaining = "hours_remaining"
            case minutesRemaining = "minutes_remaining"
        }
    }
}

class TechViewModel: ObservableObject {
    // For the main page orders (e.g., orders with downpayment)
    @Published var orders: [TechOrder] = []
    // For the scheduled orders page
    @Published var scheduledOrders: [TechOrder] = []
    
    @Published var errorMessage: String?  // For error logging
    
    private var cancellables = Set<AnyCancellable>()
    
    // Fetch orders for the main view (e.g., orders with downpayment)
    func fetchOrdersAsync() async {
        let urlString = "https://cfautocare.biz/api/tech/orders_with_downpayment"
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                self.errorMessage = "Invalid URL."
            }
            return
        }
        
        guard let token = KeychainManager.shared.retrieve(key: "userToken") else {
            await MainActor.run {
                self.errorMessage = "No authentication token found."
            }
            return
        }
        
        // 1. Create a custom URLSession configuration
        let config = URLSessionConfiguration.ephemeral
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil  // explicitly disable local caching
        
        // 2. Create a custom session using the configuration
        let session = URLSession(configuration: config)
        
        // 3. Set up your request with "no-cache" headers
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        
        do {
            // 4. Make the network call using the custom session
            let (data, response) = try await session.data(for: request)
            
            // 5. Check the HTTP status code
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                await MainActor.run {
                    self.errorMessage = "Server returned an error."
                }
                return
            }
            
            // 6. Decode your response
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decodedResponse = try decoder.decode(TechOrderResponse.self, from: data)
            
            // 7. Update the UI on the main thread
            await MainActor.run {
                self.orders = decodedResponse.orders
                print("Decoded Orders Response: \(decodedResponse)")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Fetch failed: \(error.localizedDescription)"
            }
            print("Error fetching orders: \(error)")
        }
    }
    
    // Fetch orders that have been scheduled by the technician
    func fetchScheduledOrders(for technicianId: String) {
        let urlString = "https://cfautocare.biz/api/tech/scheduled_orders?technician=\(technicianId)"
        guard let url = URL(string: urlString) else {
            self.errorMessage = "Invalid URL."
            return
        }
        
        guard let token = KeychainManager.shared.retrieve(key: "userToken") else {
            self.errorMessage = "No authentication token found."
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { result -> Data in
                guard let httpResponse = result.response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return result.data
            }
            .decode(type: TechOrderResponse.self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.errorMessage = "Something went wrong"
                    print("Error: \(error)")
                }
            } receiveValue: { response in
                // Store the fetched orders
                self.scheduledOrders = response.orders
                print("Got scheduled orders: \(response.orders)")
                
                // For each order, fetch its remaining time
                for order in self.scheduledOrders {
                    guard let orderId = order.id else { continue }
                    self.fetchRemainingTime(orderId: orderId) { formattedTime in
                        // Update by reassigning the entire struct to trigger SwiftUI update
                        if let index = self.scheduledOrders.firstIndex(where: { $0.id == orderId }) {
                            var updatedOrder = self.scheduledOrders[index]
                            updatedOrder.remainingTime = formattedTime
                            self.scheduledOrders[index] = updatedOrder
                        }
                    }
                }
            }
            .store(in: &self.cancellables)
    }

    
    
    func fetchRemainingTime(orderId: String, completion: @escaping (String?) -> Void) {
        print("fetchRemainingTime called for orderId: \(orderId)")
        
        guard let token = KeychainManager.shared.retrieve(key: "userToken") else {
            print("No token found in Keychain.")
            completion(nil)
            return
        }
        
        let urlString = "https://cfautocare.biz/api/tech/orders/\(orderId)/remaining_time"
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            completion(nil)
            return
        }
        
        print("Requesting remaining time from: \(urlString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // 1) Check for network error
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // 2) Check response code & data
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let data = data else {
                print("Unexpected response or no data. Response: \(String(describing: response))")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // 3) Print raw JSON for debugging
            if let rawJson = String(data: data, encoding: .utf8) {
                print("Raw JSON (Remaining Time): \(rawJson)")
            }
            
            // 4) Decode JSON
            do {
                let decodedResponse = try JSONDecoder().decode(RemainingTimeResponse.self, from: data)
                let timeParts = decodedResponse.remainingTime
                
                let totalHours = timeParts.hoursRemaining ?? 0
                let minutes = timeParts.minutesRemaining ?? 0
                
                // Convert large hour counts to days/hours
                let days = totalHours / 24
                let leftoverHours = totalHours % 24
                
                let formattedString = self.formatTime(days: days, hours: leftoverHours, minutes: minutes)
                
                print("Parsed remaining time: \(formattedString)")
                
                // 5) Return on main thread
                DispatchQueue.main.async {
                    completion(formattedString)
                }
            } catch {
                print("Failed decoding remaining time: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }

    
    private func formatTime(days: Int, hours: Int, minutes: Int) -> String {
        var components: [String] = []
        if days > 0 { components.append("\(days)d") }
        if hours > 0 { components.append("\(hours)h") }
        if minutes > 0 { components.append("\(minutes)m") }
        return components.isEmpty ? "0m" : components.joined(separator: " ")
    }
    
    
    
    
        func updateOrderStatus(order: TechOrder, newStatus: String, completion: @escaping (Result<String, Error>) -> Void) {
            guard let orderId = order.id,
                  let url = URL(string: "https://cfautocare.biz/api/tech/orders/\(orderId)/status") else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid order or URL."])))
                return
            }
            
            guard let token = KeychainManager.shared.retrieve(key: "userToken") else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authentication token found."])))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = ["status": newStatus]
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            } catch {
                completion(.failure(error))
                return
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    guard let httpResponse = response as? HTTPURLResponse else {
                        completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server."])))
                        return
                    }
                    if (200...299).contains(httpResponse.statusCode) {
                        // Optionally, decode a response if needed.
                        completion(.success("Order status updated successfully"))
                    } else {
                        let message = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                        completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])))
                    }
                }
            }.resume()
        }
    }

    
    
    
    
    
    
    
    
    
    
    

