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
    let finalPrice: Double?
    let vehicleSize: String?
    let clientSecret: String?
    let guestAddress: RequestGuestAddress?
    let travelFee: Double?
    let estimatedMinutes: Double?
    var remainingTime: String?


    // Computed property to format the service date and time
    var formattedServiceDateAndTime: String? {
        guard let serviceDate = serviceDate else { return nil }
        let isoFormatter = ISO8601DateFormatter()
        guard let date = isoFormatter.date(from: serviceDate) else {
            return serviceDate
        }
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
    
    
    
    
    
    
    
    
    
    
    
    
    var displayedSelectedServices: String {
           guard let services = selectedServices, !services.isEmpty else { return "N/A" }
           let serviceMapping: [String: String] = [
               "carpet_dry_detail": "Carpet Dry Detail (Vacuum)",
               "headliner_stain_removal": "Headliner Stain Removal",
               "interior_plastics_dry_detail": "Interior Plastics Dry Detail",
               "interior_plastics_wet_detail": "Interior Plastics Wet Detail/Protectants",
               "headliner_cleaning": "Headliner Cleaning",
               "seats_wet_detail": "Seats Wet Detail (Leather)",
               "seatbelts_detail": "Seatbelts Detail",
               "seats_dry_detail": "Seats Dry Detail (Vacuum)",
               "seats_shampoo": "Seats Shampoo (Fabric)",
               "bug_tar_removal": "Bug and Tar Removal",
               "claybar_wax": "Claybar/Wax",
               "extreme_pet_hair_removal": "Extreme Pet Hair Removal",
               "truckbed": "Truckbed",
               "floors_dry_detail": "Floors Dry Detail",
               "one_seat_stain_removal": "1 Seat Stain Removal",
               "floors_wet_detail": "Floors Wet Detail",
               "carpet_wet_detail": "Carpet Wet Detail (Shampoo)",
               "exterior_handwash": "Exterior Handwash and Windows",
               "light_pet_hair_removal": "Light Pet Hair Removal",
               "tire_rim_detail": "Tire and Rim Detail/Shine"
           ]
           let converted = services.map { serviceMapping[$0] ?? $0.capitalized.replacingOccurrences(of: "_", with: " ") }
           return converted.joined(separator: ", ")
       }
       
       // Convert the raw vehicle size key to a human‑readable label.
       var displayedVehicleSize: String {
           guard let vs = vehicleSize else { return "N/A" }
           let vehicleMapping: [String: String] = [
               "coupe_2_seater": "Coupe (2-Seater)",
               "hatch_2_door": "Hatchback (2-Door)",
               "hatch_4_door": "Hatchback (4-Door)",
               "truck_2_seater": "Truck (2-Seater)",
               "truck_4_seater": "Truck (4-Seater)",
               "sedan_2_door": "Sedan (2-Door)",
               "sedan_4_door": "Sedan (4-Door)",
               "suv_4_seater": "SUV (4-Seater)",
               "suv_6_seater": "SUV (6-Seater)",
               "minivan_6_seater": "Minivan (6-Seater)"
           ]
           return vehicleMapping[vs] ?? vs.capitalized.replacingOccurrences(of: "_", with: " ")
       }
    
    
    
    
    
    
    // Computed property for Tech Pay:
    // Base pay is the floor of servicesTotal.
    // Extra pay is half of travelFee, if travelFee is provided.
    var techPay: Double {
        let basePay = floor(servicesTotal ?? 0.0)
        let fee = travelFee ?? 0.0
        let extraPay = fee / 2.0
        // Debug print: uncomment the next line to see calculation details in the console.
        // print("Order \(id ?? ""): basePay=\(basePay), travelFee=\(fee), extraPay=\(extraPay), techPay=\(basePay + extraPay)")
        return basePay + extraPay
    }
    
    var displayedCompensationStatus: String {
        techCompensationStatus ?? "Pending"
    }
    
    // Coding keys remain unchanged
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
        case travelFee
        case estimatedMinutes
    }
    
    static func ==(lhs: TechOrder, rhs: TechOrder) -> Bool {
        return lhs.id == rhs.id
    }
}
