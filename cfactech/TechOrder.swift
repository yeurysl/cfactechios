//
//  techorder.swift
//  cfactech
//
//  Created by Yeurys Lora on 2/10/25.
//

import Combine
import Foundation


// The structure for the guest address
struct RequestGuestAddress: Codable {
    let streetAddress: String?
    let unitApt: String?
    let city: String?
    let country: String?
    let zipCode: String?

    enum CodingKeys: String, CodingKey {
        case streetAddress
        case unitApt
        case city
        case country
        case zipCode
    }
}

// Model for Tech Orders with necessary properties
struct TechOrderResponse: Codable {
    let orders: [TechOrder]
    let page: Int?
    let perPage: Int?
    let totalOrders: Int?
}
struct TechOrder: Identifiable, Codable, Equatable {
    let id: String?
    let guestEmail: String?
    let guestName: String?
    let guestPhoneNumber: String?
    let paymentStatus: String?
    let technician: String?
    let selectedServices: [String]?
    let seniorRvDiscount: Bool?
    let serviceDate: String?
    let servicePackage: String?
    let status: String?
    let servicesTotal: Double?
    let techCompensationStatus: String?
    
    var displayedCompensationStatus: String {
        techCompensationStatus ?? "Pending"
    }
    
    let finalPrice: Double?
    let vehicleSize: String?
    let clientSecret: String?
    let guestAddress: RequestGuestAddress?

    // New computed property to format both date and time
    var formattedServiceDateAndTime: String? {
        guard let serviceDate = serviceDate else { return nil }
        
        // Assuming the serviceDate string is in ISO8601 format.
        let isoFormatter = ISO8601DateFormatter()
        guard let date = isoFormatter.date(from: serviceDate) else {
            return serviceDate // Fallback if parsing fails.
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium    // e.g., Feb 11, 2025
        displayFormatter.timeStyle = .short       // e.g., 2:30 PM
        return displayFormatter.string(from: date)
    }
    
    // Coding keys...
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case guestEmail
        case guestName
        case guestPhoneNumber
        case paymentStatus
        case technician
        case selectedServices
        case seniorRvDiscount
        case serviceDate
        case servicePackage
        case status
        case servicesTotal
        case techCompensationStatus 
        case finalPrice
        case vehicleSize
        case clientSecret
        case guestAddress
    }
    
    static func ==(lhs: TechOrder, rhs: TechOrder) -> Bool {
        return lhs.id == rhs.id
    }
}
