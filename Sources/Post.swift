//
//  Post.swift
//  FoodBlog
//
//  Created by Tomasz on 30/09/2024.
//
import Foundation

class Post: Codable {
    var id: Int64?
    let photos: [Photo]
    let tags: [Tag]
    let title: String
    let text: String
    let date: Date
    
    init(id: Int64? = nil, photos: [Photo], tags: [Tag], title: String, text: String, date: Date) {
        self.id = id
        self.photos = photos
        self.tags = tags
        self.title = title
        self.text = text
        self.date = date
    }
}
