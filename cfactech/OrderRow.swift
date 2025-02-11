//
//  OrderRow.swift
//  cfactech
//
//  Created by Yeurys Lora on 2/11/25.
//


import SwiftUI
import Combine
import Foundation

struct OrderRow: View {
    let order: TechOrder
    let addToSchedule: (TechOrder) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Display the formatted service date and time in a prominent style.
            Text(order.formattedServiceDateAndTime ?? "N/A")
                .font(.headline)
            
            // Display guest address details.
            if let guestAddress = order.guestAddress {
                Text("City: \(guestAddress.city ?? "N/A")")
                    .font(.subheadline)
                Text("Zip Code: \(guestAddress.zipCode ?? "N/A")")
                    .font(.subheadline)
            } else {
                Text("Guest Address: N/A")
                    .font(.subheadline)
            }
            
            // A button to add the order to the schedule.
            Button(action: {
                addToSchedule(order)
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
}
