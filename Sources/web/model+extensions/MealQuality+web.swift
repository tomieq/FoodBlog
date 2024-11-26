//
//  MealQuality+web.swift
//  FoodBlog
//
//  Created by Tomasz on 26/11/2024.
//

extension MealQuality {
    var readable: String {
        switch self {
        case .awful:
            "okropne"
        case .weak:
            "słabe"
        case .average:
            "średnie"
        case .tasty:
            "smaczne"
        case .veryTasty:
            "bardzo smaczne"
        case .excellent:
            "wyśmienite"
        }
    }
}
