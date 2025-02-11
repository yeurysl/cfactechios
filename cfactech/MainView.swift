//
//  MainView.swift
//  cfactech
//
//  Created by Yeurys Lora on 2/10/25.
//
import SwiftUI
import Combine
import Foundation

struct MainView: View {
    @EnvironmentObject var techViewModel: TechViewModel
    @State private var errorMessage: String?
    @State private var technicianId: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if techViewModel.orders.isEmpty {
                    Text(techViewModel.errorMessage ?? "No orders available to be scheduled")
                        .foregroundColor(.gray)
                        .font(.title2)
                        .padding()
                        .multilineTextAlignment(.center)
                } else {
                    List(techViewModel.orders, id: \.id) { order in
                        orderCard(for: order)
                    }
                }
            }
            .navigationTitle("Orders")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: MyScheduleView()) {
                        Image(systemName: "calendar")
                            .imageScale(.large)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: TechCompensationView()) {
                        Image(systemName: "dollarsign.circle")
                            .imageScale(.large)
                    }
                }
            }
            .onAppear {
                // Retrieve the technician's user ID from Keychain (stored as "userId")
                if let techId = KeychainManager.shared.retrieve(key: "userId") {
                    technicianId = techId
                    techViewModel.fetchOrders()  // Fetch orders for the main page
                } else {
                    errorMessage = "Unable to retrieve technician ID."
                }
            }
        }
    }
    
    private func orderCard(for order: TechOrder) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Service Date: \(order.formattedServiceDateAndTime ?? "N/A")")
                .font(.headline)
            if let guestAddress = order.guestAddress {
                Text("City: \(guestAddress.city ?? "N/A")")
                    .font(.subheadline)
                Text("Zip Code: \(guestAddress.zipCode ?? "N/A")")
                    .font(.subheadline)
            } else {
                Text("Guest Address: N/A")
                    .font(.subheadline)
            }
            Button(action: {
                addToSchedule(order: order)
            }) {
                Text("Add to Schedule")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.vertical, 5)
    }
    
    func addToSchedule(order: TechOrder) {
        guard let orderId = order.id else { return }
        
        let urlString = "https://cfautocare.biz/api/tech/orders/\(orderId)"
        guard let url = URL(string: urlString) else {
            self.errorMessage = "Invalid URL."
            return
        }
        
        // Retrieve technician's user ID from Keychain (stored as "userId")
        guard let techId = KeychainManager.shared.retrieve(key: "userId") else {
            self.errorMessage = "No technician ID found."
            print("Error: No technician ID found in Keychain.")
            return
        }
        print("Technician ID retrieved: \(techId)")
        
        // Retrieve the authentication token from Keychain (stored as "userToken")
        guard let token = KeychainManager.shared.retrieve(key: "userToken") else {
            self.errorMessage = "No authentication token found."
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "technician": techId  // Pass the technician's user ID
        ]
        print("Request parameters: \(parameters)")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            self.errorMessage = "Failed to encode parameters."
            print("Error: Failed to encode parameters.")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to update the order: \(error.localizedDescription)"
                }
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to update the order."
                }
                print("Error: HTTP response status code not 200.")
                return
            }
            
            DispatchQueue.main.async {
                self.errorMessage = "Order updated successfully."
                print("Success: Order updated successfully.")
                techViewModel.fetchOrders()
            }
        }.resume()
    }
}
