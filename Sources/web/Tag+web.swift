//
//  Tag+icon.swift
//  FoodBlog
//
//  Created by Tomasz on 15/11/2024.
//

extension TagType {
    var icon: String {
        switch self {
        case .standard:
            "#"
        case .restaurantName:
            "🏢"
        case .mealName:
            "🍲"
        }
    }
}

extension Tag {
    var icon: String {
        self.tagType.icon
    }
    var pageTitle: String {
        switch tagType {
        case .standard:
            "Jem na mieście"
        case .restaurantName:
            "Odwiedzone miejsce"
        case .mealName:
            "Danie"
        }
    }
}
