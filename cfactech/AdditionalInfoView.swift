//
//  AdditionalInfoView.swift
//  cfactech
//
//  Created by Yeurys Lora on 2/13/25.
//
import SwiftUI
import Foundation
import Combine







struct AdditionalInfoView: View {
    let order: TechOrder
    let onClose: () -> Void

    // Compute estimated time from order.estimatedMinutes (in minutes)
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
    
    // Display selected services as a bullet list
    var selectedServicesView: some View {
        Group {
            if let services = order.selectedServices, !services.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Selected Services:")
                        .fontWeight(.medium)
                    ForEach(services, id: \.self) { service in
                        Text("• \(service.humanReadable)")
                    }
                }
            } else {
                InfoRow(title: "Selected Services", value: "N/A")
            }
        }
    }
    
    // Vehicle size string in a human-readable format.
    var vehicleSizeString: String {
        order.vehicleSize?.humanReadable ?? "N/A"
    }
    
    // Payment info: total tech pay calculated as base pay plus half travel fee.
    var totalTechPay: String {
        if let servicesTotal = order.servicesTotal {
            let basePay = floor(servicesTotal)
            let extraPay = (order.travelFee ?? 0.0) / 2.0
            return String(format: "$%.2f", basePay + extraPay)
        } else {
            return "N/A"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("Additional Information")
                .font(.headline)
            
            Divider()
            
            // Payment Info Card
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(title: "Total Tech Pay", value: totalTechPay)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Timing Info Card
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(title: "Estimated Time", value: estimatedTime)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Services & Vehicle Info Card
            VStack(alignment: .leading, spacing: 12) {
                selectedServicesView
                InfoRow(title: "Vehicle Size", value: vehicleSizeString)
                InfoRow(title: "Your Pay", value: String(format: "$%.2f", order.techPay))
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
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
            .padding(.top, 20)
        }
        .padding()
        .frame(maxWidth: 300)
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
}

