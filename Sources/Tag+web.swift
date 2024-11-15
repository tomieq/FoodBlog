//
//  Tag+icon.swift
//  FoodBlog
//
//  Created by Tomasz on 15/11/2024.
//

extension Tag {
    var icon: String {
        switch type {
        case .standard:
            "#"
        case .restaurantName:
            "🏢"
        case .mealName:
            "🍲"
        }
    }
    var pageTitle: String {
        switch type {
        case .standard:
            "Jem na mieście"
        case .restaurantName:
            "Odwiedzone miejsce"
        case .mealName:
            "Danie"
        }
    }
}
