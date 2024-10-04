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
    
    func createPhoto() throws -> Photo {
        let photo = Photo(postID: 0, filename: UUID().uuidString + ".jpg")
        try PhotoTable.store(db: connection, photo)
        return photo
    }
}
