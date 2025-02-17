//
//  OrderCardView.swift
//  cfactech
//
//  Created by Yeurys Lora on 2/13/25.
//


import SwiftUI

struct OrderCardView: View {
    let order: TechOrder
    let addToSchedule: (TechOrder, @escaping () -> Void) -> Void
    @Binding var orderShowingPopover: TechOrder?
    @State private var isScheduling: Bool = false
    @State private var showConfirmAlert: Bool = false

    var estimatedHourlyRate: String {
           guard let minutes = order.estimatedMinutes, minutes > 0 else { return "N/A" }
           let rate = order.techPay * 60 / minutes
           return String(format: "$%.2f/hr", rate)
       }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 10) {
                // Service date and time
                Text("Service Date: \(order.formattedServiceDateAndTime ?? "N/A")")
                    .font(.headline)
                
                // Tech pay in a blue bar
                Text("\(String(format: "$%.2f", order.techPay)) - Estimated \(estimatedHourlyRate)")
                                 .font(.subheadline)
                                 .foregroundColor(.blue)
                                 .padding(8)
                                 .background(Color.blue.opacity(0.1))
                                 .cornerRadius(8)
                             
                // Guest address details
                if let guestAddress = order.guestAddress {
                    Text("City: \(guestAddress.city ?? "N/A")")
                        .font(.subheadline)
                    Text("Zip Code: \(guestAddress.zipCode ?? "N/A")")
                        .font(.subheadline)
                } else {
                    Text("Guest Address: N/A")
                        .font(.subheadline)
                }
                
                // "Add to Schedule" button
                Button(action: {
                    // Show confirmation alert before scheduling
                    showConfirmAlert = true
                }) {
                    Text(isScheduling ? "Scheduling..." : "Add to Schedule")
                        .foregroundColor(.white)
                        .padding()
                        .background(isScheduling ? Color.gray : Color.blue)
                        .cornerRadius(8)
                }
            }
            .padding()
            .frame(minHeight: 120)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .shadow(radius: 5)
            .padding(.vertical, 5)
            
            // Ellipsis button for additional info
            EllipsisButton(order: order, orderShowingPopover: $orderShowingPopover)
                .padding(8)
        }
        // Confirmation alert for scheduling
        .alert(isPresented: $showConfirmAlert) {
            Alert(
                title: Text("Confirm Schedule"),
                message: Text("Are you sure you want to schedule this order?"),
                primaryButton: .default(Text("Yes"), action: {
                    isScheduling = true
                    addToSchedule(order) {
                        // Reset scheduling state when done
                        isScheduling = false
                    }
                }),
                secondaryButton: .cancel({
                    // Optionally handle cancellation
                    showConfirmAlert = false
                })
            )
        }
    }
}
