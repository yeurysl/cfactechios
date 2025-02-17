//
//  EllipsisButton.swift
//  cfactech
//
//  Created by Yeurys Lora on 2/13/25.
//
import SwiftUI
import Combine
import Foundation


struct EllipsisButton: View {
    let order: TechOrder
    @Binding var orderShowingPopover: TechOrder?

    var body: some View {
        Button(action: {
            orderShowingPopover = order
        }) {
            Image(systemName: "ellipsis.circle.fill")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(.gray)
                .padding(4)
                .background(Color.white.opacity(0.8))
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: Binding(
            get: { orderShowingPopover?.id == order.id },
            set: { newValue in if !newValue { orderShowingPopover = nil } }
        )) {
            AdditionalInfoView(order: order, onClose: {
                orderShowingPopover = nil
            })
        }
    }
}
