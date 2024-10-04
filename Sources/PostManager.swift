//
//  PostManager.swift
//  FoodBlog
//
//  Created by Tomasz on 04/10/2024.
//
import SQLite
import Foundation

struct PostManager {
    let db: Connection
    
    init(db: Connection) throws {
        self.db = db
        try PostTable.create(db: db)
    }
    
    func store(title: String, text: String, date: Date, photoIDs: [Int64]) throws -> Post {
        let post = Post(photos: try PhotoTable.get(db: db, ids: photoIDs),
                        tags: [],
                        title: title,
                        text: text,
                        date: date)
        try PostTable.store(db: db, post)
        for photo in post.photos {
            photo.postID = post.id!
            try PhotoTable.store(db: db, photo)
        }
        return post
    }
    
    func list() throws -> [Post] {
        let posts = try PostTable.get(db: db)
        try posts.forEach { post in
            try post.photos = PhotoTable.get(db: db, postID: post.id!)
        }
        return posts
    }
}
