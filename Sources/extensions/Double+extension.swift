//
//  Double+extension.swift
//  FoodBlog
//
//  Created by Tomasz on 15/11/2024.
//

extension Double {
    var price: String {
        String(format: "%.2f", self).replacingOccurrences(of: ".00", with: "")
    }
}
