//
//  Tag.swift
//  FoodBlog
//
//  Created by Tomasz on 30/09/2024.
//

class Tag: Codable {
    var id: Int64?
    let name: String
    let seoName: String
    
    init(id: Int64? = nil, name: String, seoName: String) {
        self.id = id
        self.name = name
        self.seoName = seoName
    }
}
