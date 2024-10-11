//
//  Post.swift
//  FoodBlog
//
//  Created by Tomasz on 30/09/2024.
//
import Foundation

class Post: Codable {
    var id: Int64?
    var photos: [Photo]
    let title: String
    let text: String
    let date: Date
    
    init(id: Int64? = nil, photos: [Photo], title: String, text: String, date: Date) {
        self.id = id
        self.photos = photos
        self.title = title
        self.text = text
        self.date = date
    }
}
