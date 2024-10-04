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
