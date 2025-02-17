//
//  TechCompensationView.swift
//  cfactech
//
//  Created by Yeurys Lora on 2/11/25.
//


import SwiftUI
import Combine
import Foundation

struct TechCompensationView: View {
    @EnvironmentObject var techViewModel: TechViewModel
    @State private var errorMessage: String?
    @State private var technicianId: String = ""
    
    var body: some View {
        VStack {
            if techViewModel.scheduledOrders.isEmpty {
                Text(errorMessage ?? "No scheduled orders found")
                    .foregroundColor(.gray)
                    .font(.title2)
                    .padding()
                    .multilineTextAlignment(.center)
            } else {
                List(techViewModel.scheduledOrders, id: \.id) { order in
                    CompensationOrderRow(order: order)
                }
            }
        }
        .navigationTitle("Compensation")
        .onAppear {
            if let techId = KeychainManager.shared.retrieve(key: "userId") {
                technicianId = techId
                techViewModel.fetchScheduledOrders(for: techId)
            } else {
                errorMessage = "Unable to retrieve technician ID."
            }
        }
    }
}
