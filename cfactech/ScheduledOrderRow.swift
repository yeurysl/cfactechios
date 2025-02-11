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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Service Date & Time header (prominent)
            Text(order.formattedServiceDateAndTime ?? "N/A")
                .font(.system(size: 30, weight: .bold))
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            // Address: combine the available address components into one line.
            if let guestAddress = order.guestAddress {
                let addressLine = [
                    guestAddress.streetAddress,
                    guestAddress.unitApt,
                    guestAddress.city,
                    guestAddress.zipCode
                ]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
                
                Text(addressLine)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Guest Address: N/A")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Phone Number (displayed under the address)
            Text("Phone: \(order.guestPhoneNumber ?? "N/A")")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Button that opens the Maps app with the address.
            if let guestAddress = order.guestAddress {
                Button(action: {
                    openMaps(with: guestAddress)
                }) {
                    Text("Open in Maps")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.vertical, 5)
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
        
        // Make sure the address is URL encoded.
        if let encodedAddress = addressLine.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "http://maps.apple.com/?address=\(encodedAddress)") {
            openURL(url)
        }
    }
}
