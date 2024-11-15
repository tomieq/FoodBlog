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
    let tagType: TagType
    
    init(id: Int64? = nil,
         name: String,
         seoName: String,
         tagType: TagType) {
        self.id = id
        self.name = name
        self.seoName = seoName
        self.tagType = tagType
    }
}
