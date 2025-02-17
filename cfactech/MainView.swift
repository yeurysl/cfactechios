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
    @State private var orderShowingPopover: TechOrder? = nil
    
  
    
    var body: some View {
        NavigationView {
            VStack {
                if techViewModel.orders.isEmpty {
                    // If the orders array is empty:
                    if let _ = techViewModel.errorMessage {
                        // If there's an error message, show a user-friendly placeholder:
                        Text("No orders available at this time. Please try again later.")
                            .foregroundColor(.gray)
                            .font(.title2)
                            .padding()
                            .multilineTextAlignment(.center)
                    } else {
                        // If there's no error message, just show a generic "No orders" message:
                        Text("No orders available to be scheduled")
                            .foregroundColor(.gray)
                            .font(.title2)
                            .padding()
                            .multilineTextAlignment(.center)
                    }
                } else {
                    // If orders are not empty, show the List
                    List(techViewModel.orders, id: \.id) { order in
                        OrderCardView(order: order,
                                      addToSchedule: addToSchedule,
                                      orderShowingPopover: $orderShowingPopover)
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await techViewModel.fetchOrdersAsync()
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
                loadData()
            }
        }
    }

    private func loadData() {
        if let techId = KeychainManager.shared.retrieve(key: "userId") {
            technicianId = techId
            Task {
                await techViewModel.fetchOrdersAsync()
            }
        } else {
            errorMessage = "Unable to retrieve technician ID."
        }
    }

    func addToSchedule(order: TechOrder, completion: @escaping () -> Void) {
        guard let orderId = order.id else { return }
        
        let urlString = "https://cfautocare.biz/api/tech/orders/\(orderId)"
        guard let url = URL(string: urlString) else {
            self.errorMessage = "Invalid URL."
            completion()
            return
        }

        // Retrieve technician's user ID from Keychain
        guard let techId = KeychainManager.shared.retrieve(key: "userId") else {
            self.errorMessage = "No technician ID found."
            print("Error: No technician ID found in Keychain.")
            completion()
            return
        }
        print("Technician ID retrieved: \(techId)")
        
        // Retrieve authentication token from Keychain
        guard let token = KeychainManager.shared.retrieve(key: "userToken") else {
            self.errorMessage = "No authentication token found."
            completion()
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "technician": techId
        ]
        print("Request parameters: \(parameters)")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            self.errorMessage = "Failed to encode parameters."
            print("Error: Failed to encode parameters.")
            completion()
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to update the order: \(error.localizedDescription)"
                    completion()
                }
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to update the order."
                    completion()
                }
                print("Error: HTTP response status code not 200.")
                return
            }
            
            DispatchQueue.main.async {
                self.errorMessage = "Order updated successfully."
                print("Success: Order updated successfully.")
                Task {
                    await techViewModel.fetchOrdersAsync()
                }
                
                completion()
            }
        }.resume()
    }
}
