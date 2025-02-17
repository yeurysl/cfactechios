//
//  AdditionalInfoScheduledView.swift
//  cfactech
//
//  Created by Yeurys Lora on 2/13/25.
//

import SwiftUI
import Foundation
import Combine








struct AdditionalInfoScheduledView: View {
    let order: TechOrder
    let onClose: () -> Void
    @State private var remainingTime: String?
    @State private var remainingTimeError: String?
    
    // Computed property for estimated time (assumed to be in minutes)
    var estimatedTime: String {
        let totalMinutes = order.estimatedMinutes ?? 0
        if totalMinutes >= 60 {
            let hours = Int(totalMinutes) / 60
            let minutes = Int(totalMinutes) % 60
            return "\(hours)h \(minutes)m"
        } else {
            return "\(Int(totalMinutes)) min"
        }
    }
    
    // Computed property for guest address string (each component on its own line)
    var guestAddressView: some View {
        Group {
            if let addr = order.guestAddress {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Guest Address:")
                        .fontWeight(.medium)
                    if let street = addr.streetAddress, !street.isEmpty {
                        Text(street)
                    }
                    if let unit = addr.unitApt, !unit.isEmpty {
                        Text(unit)
                    }
                    if let city = addr.city, !city.isEmpty {
                        Text(city)
                    }
                    if let zip = addr.zipCode, !zip.isEmpty {
                        Text(zip)
                    }
                }
            } else {
                InfoRow(title: "Guest Address", value: "N/A")
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
           
            // Order Information Card
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(title: "Order ID", value: order.id ?? "N/A")
                Divider()
                InfoRow(title: "Guest Name", value: order.guestName ?? "N/A")
                Divider()
                InfoRow(title: "Guest Phone", value: order.guestPhoneNumber ?? "N/A")
                Divider()
                guestAddressView
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            
            // Timing Information Card
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(title: "Estimated Time", value: estimatedTime)
                Divider()
                if let remainingTime = remainingTime {
                    InfoRow(title: "Remaining Time", value: remainingTime, valueColor: .green)
                }
                if let error = remainingTimeError {
                    InfoRow(title: "Time Error", value: error, valueColor: .red)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            
            // Services & Compensation Card
            VStack(alignment: .leading, spacing: 12) {
                if !order.displayedSelectedServices.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Selected Services:")
                            .fontWeight(.medium)
                        ForEach(order.displayedSelectedServices.components(separatedBy: ", "), id: \.self) { service in
                            Text("• \(service)")
                        }
                    }
                } else {
                    InfoRow(title: "Selected Services", value: "N/A")
                }
                Divider()
                InfoRow(title: "Vehicle Size", value: order.displayedVehicleSize)
                Divider()
                InfoRow(title: "Your Pay", value: String(format: "$%.2f", order.techPay))
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            Spacer()
            
            // Close Button
            Button(action: {
                onClose()
            }) {
                Text("Close")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .frame(maxWidth: 350)
        .onAppear {
            fetchRemainingTime()
        }
    }
    
    @ViewBuilder
    func InfoRow(title: String, value: String, valueColor: Color = .primary) -> some View {
        HStack {
            Text("\(title):")
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
                .multilineTextAlignment(.trailing)
        }
    }
    
    func fetchRemainingTime() {
        guard let orderId = order.id,
              let url = URL(string: "https://cfautocare.biz/api/tech/orders/\(orderId)/remaining_time") else {
            remainingTimeError = "Invalid order or URL."
            return
        }
        
        guard let token = KeychainManager.shared.retrieve(key: "userToken") else {
            remainingTimeError = "No authentication token found."
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("AdditionalInfoScheduledView: Requesting remaining time for order \(orderId)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.remainingTimeError = "Error: \(error.localizedDescription)"
                    print("Network error: \(error.localizedDescription)")
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode),
                      let data = data else {
                    self.remainingTimeError = "Invalid response from server."
                    print("Invalid response: \(String(describing: response))")
                    return
                }
                
                if let rawJson = String(data: data, encoding: .utf8) {
                    print("Raw JSON (Additional Info - Remaining Time): \(rawJson)")
                }
                
                do {
                    let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let remainingTimeData = jsonResponse?["remaining_time"] as? [String: Any] {
                        let hoursRemaining = remainingTimeData["hours_remaining"] as? Int ?? 0
                        let minutesRemaining = remainingTimeData["minutes_remaining"] as? Int ?? 0
                        
                        let totalMinutes = hoursRemaining * 60 + minutesRemaining
                        
                        if totalMinutes > 29 * 24 * 60 {
                            self.remainingTime = "Over a month away"
                        } else if totalMinutes > 7 * 24 * 60 {
                            let weeks = totalMinutes / (7 * 24 * 60)
                            self.remainingTime = "\(weeks) week\(weeks > 1 ? "s" : "") remaining"
                        } else if totalMinutes > 24 * 60 {
                            let days = totalMinutes / (24 * 60)
                            self.remainingTime = "\(days) day\(days > 1 ? "s" : "") remaining"
                        } else {
                            self.remainingTime = "\(hoursRemaining) hour\(hoursRemaining > 1 ? "s" : "") and \(minutesRemaining) minute\(minutesRemaining != 1 ? "s" : "") remaining"
                        }
                        print("Parsed remaining time: \(self.remainingTime ?? "nil")")
                    } else {
                        self.remainingTimeError = "Unable to parse remaining time data."
                    }
                } catch {
                    self.remainingTimeError = "Failed to parse remaining time data."
                    print("Parsing error: \(error)")
                }
            }
        }.resume()
    }
}
