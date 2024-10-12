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
        let post = Post(title: title,
                        text: text,
                        date: date)
        try PostTable.store(db: db, post)
        for photo in try PhotoTable.get(db: db, ids: photoIDs) {
            photo.postID = post.id!
            photo.sequence = photoIDs.firstIndex(of: photo.id!) ?? 0
            try PhotoTable.store(db: db, photo)
        }
        return post
    }
    
    func update(_ post: Post, title: String, text: String, date: Date, photoIDs: [Int64]) throws -> Post {
        let updatedPost = Post(id: post.id,
                               title: title,
                               text: text,
                               date: date)
        try PostTable.store(db: db, updatedPost)
        // unassign
        for photo in try PhotoTable.get(db: db, postID: post.id!) where photoIDs.contains(photo.id!).not {
            photo.postID = 0
            photo.sequence = 0
            try PhotoTable.store(db: db, photo)
        }
        // assign with proper sequence
        for photo in try PhotoTable.get(db: db, ids: photoIDs) {
            let sequence = photoIDs.firstIndex(of: photo.id!) ?? 0
            if photo.postID != post.id || photo.sequence != sequence {
                photo.postID = post.id!
                photo.sequence = sequence
                try PhotoTable.store(db: db, photo)
            }
        }
        return updatedPost
    }
    
    func list(limit: Int, page: Int) throws -> [Post] {
        try PostTable.get(db: db, limit: limit, offset: limit * page)
    }
    
    func list(ids: [Int64], limit: Int, page: Int) throws -> [Post] {
        try PostTable.get(db: db, ids: ids, limit: limit, offset: limit * page)
    }
    
    func get(id: Int64) throws -> Post? {
        try PostTable.get(db: db, id: id)
    }
}
