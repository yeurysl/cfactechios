//
//  ChangeOrderStatusView.swift
//  cfactech
//
//  Created by Yeurys Lora on 2/16/25.
//


import SwiftUI
import Combine





struct ChangeOrderStatusView: View {
    let order: TechOrder
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: TechViewModel  // or use @EnvironmentObject if preferred
    let onClose: () -> Void

    // Three possible status triggers.
    let statusOptions = ["On the Way", "Have to reschedule", "Completed"]

    @State private var selectedStatus: String = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Current Status").font(.headline)) {
                    Text(order.status?.humanReadable ?? "N/A")
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Select New Status").font(.headline)) {
                    Picker("Status", selection: $selectedStatus) {
                        ForEach(statusOptions, id: \.self) { status in
                            Text(status)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section {
                    Button("Update Status") {
                        updateStatus()
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                if let successMessage = successMessage {
                    Section {
                        Text(successMessage)
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Order Status")
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
                onClose()
            })
            .onAppear {
                // Pre-select the current status in human-readable format.
                if let current = order.status {
                    let humanStatus = current.humanReadable
                    if statusOptions.contains(humanStatus) {
                        selectedStatus = humanStatus
                    } else {
                        selectedStatus = statusOptions.first!
                    }
                } else {
                    selectedStatus = statusOptions.first!
                }
            }
        }
    }
    
    // Converts a human-readable status (e.g., "On the Way") to a database-friendly format (e.g., "on_the_way").
    func convertStatusForDatabase(_ status: String) -> String {
        return status.lowercased().replacingOccurrences(of: " ", with: "_")
    }
    
    func updateStatus() {
        let dbStatus = convertStatusForDatabase(selectedStatus)
        viewModel.updateOrderStatus(order: order, newStatus: dbStatus) { result in
            switch result {
            case .success(let message):
                self.successMessage = message
                self.errorMessage = nil
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.successMessage = nil
            }
        }
    }
}
