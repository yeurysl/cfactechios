
import Foundation
import Combine

extension String {
    
    var humanReadable: String {
           return self
               .replacingOccurrences(of: "_", with: " ")
               .capitalized
       }
    /// Converts an ISO8601 date string to a formatted string like "January 12th, 2024".
    func formattedDate() -> String {
        let isoFormatter = ISO8601DateFormatter()
        // Try to parse the string as an ISO8601 date.
        guard let date = isoFormatter.date(from: self) else { return self }
        
        // Extract the month, day, and year.
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let monthNumber = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        // Use a DateFormatter to get the full month name.
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        let month = dateFormatter.string(from: date)
        
        // Compute the ordinal suffix for the day.
        let suffix: String = {
            let tens = day % 100
            let ones = day % 10
            if tens >= 11 && tens <= 13 {
                return "th"
            }
            switch ones {
            case 1: return "st"
            case 2: return "nd"
            case 3: return "rd"
            default: return "th"
            }
        }()
        
        return "\(month) \(day)\(suffix), \(year)"
    }
}
