//
//  CompensationOrderRow.swift
//  cfactech
//
//  Created by Yeurys Lora on 2/11/25.
//


import SwiftUI

struct CompensationOrderRow: View {
    let order: TechOrder
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(order.formattedServiceDateAndTime ?? "N/A")
                    .font(.headline)
                if let guestAddress = order.guestAddress {
                    Text("\(guestAddress.city ?? "N/A"), \(guestAddress.zipCode ?? "N/A")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Guest Address: N/A")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            // Display compensation status on the right, defaulting to "Pending"
            Text(order.displayedCompensationStatus)
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.vertical, 5)
    }
}
