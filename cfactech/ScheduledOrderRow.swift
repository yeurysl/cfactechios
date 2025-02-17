//
//  ScheduledOrderRow.swift
//  cfactech
//
//  Created by Yeurys Lora on 2/11/25.
//


import SwiftUI
import Combine
import Foundation






struct ScheduledOrderRow: View {
    let order: TechOrder
    @Environment(\.openURL) var openURL
    @EnvironmentObject var viewModel: TechViewModel  // Inject your view model
    @State private var showAdditionalInfoScheduled = false
    @State private var showChangeStatus = false
    @State private var remainingTime: String?
    @State private var remainingTimeError: String?
    
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
    
    var estimatedHourlyRate: String {
        guard let minutes = order.estimatedMinutes, minutes > 0 else { return "N/A" }
        let hours = Double(minutes) / 60.0
        let rate = order.techPay / hours
        return String(format: "$%.2f/hr", rate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Service Date & Time header (prominent)
            Text(order.formattedServiceDateAndTime ?? "N/A")
                .font(.system(size: 30, weight: .bold))
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            // HStack for Tech Pay, Estimated Time and Open in Maps Button
            HStack(alignment: .center) {
                // VStack for Tech Pay, Estimated Time, and Estimated Hourly Rate
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "$%.2f", order.techPay))
                        .font(.title2)
                    
                    HStack(spacing: 4) {
                        Text(estimatedTime)
                            .font(.title3) // Slightly smaller than tech pay
                        Text(estimatedHourlyRate)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // "Directions" button positioned to the right with extra left padding
                if let guestAddress = order.guestAddress {
                    Button(action: {
                        openMaps(with: guestAddress)
                    }) {
                        Text("Directions")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.leading, 36) // Extra left padding to push it further right
                    .frame(maxWidth: 250, alignment: .center)
                    .contentShape(Rectangle())
                }
            }
            .padding(.vertical, 4)
            
            // Display Remaining Time
            if let remainingTime = remainingTime {
                Text(remainingTime)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            // Display error if any
            if let error = remainingTimeError {
                HStack {
                    Text("Error fetching remaining time:")
                    Spacer()
                    Text(error)
                        .foregroundColor(.red)
                }
            }
            
            // Buttons: Change Status and Additional Info (ellipsis)
            HStack {
                Button(action: {
                    showChangeStatus.toggle()
                }) {
                    Text("Change Status")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .fixedSize()  // Ensure the button takes up only as much space as it needs
                
                Spacer()
                
                Button(action: {
                    showAdditionalInfoScheduled.toggle()
                }) {
                    Image(systemName: "ellipsis")
                        .font(.title)
                        .foregroundColor(.gray)
                        .padding(8)
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())  // Limit the tappable area to the button’s bounds
                .fixedSize()  // Ensure the button takes up only as much space as it needs
            }
            .padding(.top, 8)

        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.vertical, 5)
        .onAppear {
            fetchRemainingTime()
        }
        // Present ChangeOrderStatusView as a sheet
        .sheet(isPresented: $showChangeStatus) {
            ChangeOrderStatusView(order: order, viewModel: viewModel, onClose: {
                showChangeStatus = false
            })
        }
        // Present AdditionalInfoScheduledView as a popover
        .popover(isPresented: $showAdditionalInfoScheduled, arrowEdge: .bottom) {
            AdditionalInfoScheduledView(order: order, onClose: {
                showAdditionalInfoScheduled = false
            })
        }
    }
    
    /// Constructs a URL using the guest address and opens it in the Maps app.
    func openMaps(with address: RequestGuestAddress) {
        let addressLine = [
            address.streetAddress,
            address.unitApt,
            address.city,
            address.zipCode
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: ", ")
        
        if let encodedAddress = addressLine.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "http://maps.apple.com/?address=\(encodedAddress)") {
            openURL(url)
        }
    }
    
    /// Fetches the remaining time for this order using the API,
    /// then updates the state.
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
        
        print("fetchRemainingTime: Requesting remaining time for order \(orderId)")
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.remainingTimeError = "Error: \(error.localizedDescription)"
                    print("Network error: \(error.localizedDescription)")
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.remainingTimeError = "Invalid response from server."
                    print("Invalid response.")
                    return
                }
                if (200...299).contains(httpResponse.statusCode), let data = data {
                    if let rawJson = String(data: data, encoding: .utf8) {
                        print("Raw JSON (Remaining Time): \(rawJson)")
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
                } else {
                    self.remainingTimeError = "Failed to fetch remaining time. Status code: \(httpResponse.statusCode)"
                    print("HTTP error: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
}
