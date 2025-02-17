//
//  MyScheduleView.swift
//  cfactech
//
//  Created by Yeurys Lora on 2/11/25.
//




import SwiftUI
import Combine
import Foundation



struct MyScheduleView: View {
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
                // Use List's built-in pull-to-refresh functionality
                List(techViewModel.scheduledOrders, id: \.id) { order in
                    ScheduledOrderRow(order: order)
                }
                .refreshable {
                    refreshData()
                }
            }
        }
        .navigationTitle("My Schedule")
        .onAppear {
            loadData()
        }
    }
    
    // Helper function to load data initially
    private func loadData() {
        if let techId = KeychainManager.shared.retrieve(key: "userId") {
            technicianId = techId
            techViewModel.fetchScheduledOrders(for: techId)
        } else {
            errorMessage = "Unable to retrieve technician ID."
        }
    }
    
    // Helper function to refresh data when user pulls down on the list
    private func refreshData() {
        if let techId = KeychainManager.shared.retrieve(key: "userId") {
            technicianId = techId
            // Fetch updated scheduled orders
            techViewModel.fetchScheduledOrders(for: techId)
        } else {
            errorMessage = "Unable to retrieve technician ID."
        }
    }
}
