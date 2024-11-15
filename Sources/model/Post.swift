//
//  Post.swift
//  FoodBlog
//
//  Created by Tomasz on 30/09/2024.
//
import Foundation

class Post: Codable {
    var id: Int64?
    let title: String
    let text: String
    let date: Date
    let mealPrice: Double?
    
    init(id: Int64? = nil,
         title: String,
         text: String,
         date: Date,
         mealPrice: Double?) {
        self.id = id
        self.title = title
        self.text = text
        self.date = date
        self.mealPrice = mealPrice
    }
}
