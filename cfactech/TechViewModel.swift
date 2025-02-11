//
//  TechViewModel.swift
//  cfactech
//
//  Created by Yeurys Lora on 2/11/25.
//


import Combine
import Foundation


class TechViewModel: ObservableObject {
    // For the main page orders (e.g., orders with downpayment)
    @Published var orders: [TechOrder] = []
    // For the scheduled orders page
    @Published var scheduledOrders: [TechOrder] = []
    
    @Published var errorMessage: String?  // For error logging
    
    private var cancellables = Set<AnyCancellable>()
    
    // Fetch orders for the main view (e.g., orders with downpayment)
    func fetchOrders() {
        let urlString = "https://cfautocare.biz/api/tech/orders_with_downpayment"
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
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { result -> Data in
                guard let httpResponse = result.response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                if let jsonString = String(data: result.data, encoding: .utf8) {
                    print("Raw JSON (Orders): \(jsonString)")
                }
                return result.data
            }
            .decode(type: TechOrderResponse.self, decoder: {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return decoder
            }())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case let .failure(error) = completion {
                    self.errorMessage = "No orders available to be scheduled"
                    print("Decoding error (Orders): \(error)")
                }
            } receiveValue: { response in
                print("Decoded Orders Response: \(response)")
                self.orders = response.orders
            }
            .store(in: &cancellables)
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
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { result -> Data in
                guard let httpResponse = result.response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                if let jsonString = String(data: result.data, encoding: .utf8) {
                    print("Raw JSON (Scheduled Orders): \(jsonString)")
                }
                return result.data
            }
            .decode(type: TechOrderResponse.self, decoder: {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return decoder
            }())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case let .failure(error) = completion {
                    self.errorMessage = "No scheduled orders available"
                    print("Decoding error (Scheduled Orders): \(error)")
                }
            } receiveValue: { response in
                print("Decoded Scheduled Orders Response: \(response)")
                self.scheduledOrders = response.orders
            }
            .store(in: &cancellables)
    }
}
