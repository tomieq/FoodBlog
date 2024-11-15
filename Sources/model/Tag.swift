//
//  Tag.swift
//  FoodBlog
//
//  Created by Tomasz on 30/09/2024.
//

enum TagType: Int, Codable, CaseIterable {
    case standard
    case restaurantName
    case mealName
}

class Tag: Codable {
    var id: Int64?
    let name: String
    let seoName: String
    let type: TagType
    
    init(id: Int64? = nil,
         name: String,
         seoName: String,
         type: TagType) {
        self.id = id
        self.name = name
        self.seoName = seoName
        self.type = type
    }
}
