//
//  Date+extension.swift
//  FoodBlog
//
//  Created by Tomasz on 04/10/2024.
//
import Foundation

extension Date {
    var readable: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.string(from: self)
    }
}

extension Date {
    static func make(from text: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from:text)
    }
}

extension Date {
    var dayOfWeek: String {
        let calendar = Calendar(identifier: .gregorian)
        let weekday = calendar.component(.weekday, from: self)
        
        switch weekday {
        case 1: return "Niedziela"
        case 2: return "Poniedziałek"
        case 3: return "Wtorek"
        case 4: return "Środa"
        case 5: return "Czwartek"
        case 6: return "Piątek"
        case 7: return "Sobota"
        default: return "Nieznany dzień"
        }
    }
}
