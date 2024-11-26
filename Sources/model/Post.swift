//
//  Post.swift
//  FoodBlog
//
//  Created by Tomasz on 30/09/2024.
//
import Foundation

enum MealQuality: Int, Codable, CaseIterable {
    case awful = 1
    case weak = 3
    case average = 5
    case tasty = 7
    case veryTasty = 8
    case excellent = 10
}

class Post: Codable {
    var id: Int64?
    let title: String
    let text: String
    let date: Date
    let mealPrice: Double?
    let mealQuality: MealQuality?
    
    init(id: Int64? = nil,
         title: String,
         text: String,
         date: Date,
         mealPrice: Double?,
         mealQuality: MealQuality?) {
        self.id = id
        self.title = title
        self.text = text
        self.date = date
        self.mealPrice = mealPrice
        self.mealQuality = mealQuality
    }
}
