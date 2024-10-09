//
//  PostManagerTests.swift
//  FoodBlog
//
//  Created by Tomasz on 04/10/2024.
//

import Testing
import SQLite
import Foundation
@testable import FoodBlog

struct PostManagerTests {
    let connection: Connection
    let photoManager: PhotoManager
    let postManager: PostManager
    
    init() throws {
        connection = try Connection(.inMemory)
        photoManager = try PhotoManager(db: connection)
        postManager = try PostManager(db: connection)
    }
    
    @Test func storing() async throws {
        let photoIDs = try (1...3).compactMap { _ in try createPhoto().id }
        let post = try postManager.store(title: "New post", text: "Awesome food!", date: Date(), photoIDs: photoIDs)

        for photo in post.photos {
            #expect(photo.postID == post.id)
        }
    }
    
    @Test func pagination() async throws {
        for i in 1...20 {
            _ = try postManager.store(title: "Post \(i)", text: "Content \(i)", date: Date(), photoIDs: [])
        }
        let page0 = try postManager.list(limit: 5, page: 0)
        #expect(page0.count == 5)
        #expect(page0.map{ $0.title }.contains("Post 20"))
        #expect(page0.map{ $0.title }.contains("Post 16"))
        let page1 = try postManager.list(limit: 5, page: 1)
        #expect(page1.count == 5)
        #expect(page1.map{ $0.title }.contains("Post 15"))
        #expect(page1.map{ $0.title }.contains("Post 11"))
    }
    
    func createPhoto() throws -> Photo {
        let photo = Photo(postID: 0, filename: UUID().uuidString + ".jpg")
        try PhotoTable.store(db: connection, photo)
        return photo
    }
}
