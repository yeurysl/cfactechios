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
                // Instead of guest address, display order ID
                Text("Order ID: \(order.id ?? "N/A")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            // Combine tech pay and status into one line.
            Text("\(String(format: "$%.2f", order.techPay)) - \(order.techCompensationStatus ?? "Pending")")
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
