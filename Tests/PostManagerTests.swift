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
    let tagManager: TagManager
    
    init() throws {
        connection = try Connection(.inMemory)
        photoManager = try PhotoManager(db: connection)
        postManager = try PostManager(db: connection)
        tagManager = try TagManager(db: connection)
    }
    
    @Test func storing() async throws {
        let photoIDs = try (1...3).compactMap { _ in try createPhoto().id }
        let post = try postManager.store(title: "New post",
                                         text: "Awesome food!",
                                         date: Date(),
                                         photoIDs: photoIDs,
                                         mealPrice: 29)

        for photo in try PhotoTable.get(db: connection, ids: photoIDs) {
            #expect(photo.postID == post.id)
        }
    }
    
    @Test func storingWithPhotoSequence() async throws {
        _ = try (1...3).compactMap { _ in try createPhoto().id }
        _ = try postManager.store(title: "New post",
                                  text: "Awesome food!",
                                  date: Date(),
                                  photoIDs: [3, 1, 2],
                                  mealPrice: 29)

        #expect(try PhotoTable.get(db: connection, id: 3)?.sequence == 0)
        #expect(try PhotoTable.get(db: connection, id: 1)?.sequence == 1)
        #expect(try PhotoTable.get(db: connection, id: 2)?.sequence == 2)
    }
    
    @Test func pagination() async throws {
        for i in 1...20 {
            _ = try postManager.store(title: "Post \(i)",
                                      text: "Content \(i)",
                                      date: Date(),
                                      photoIDs: [],
                                      mealPrice: 29)
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
    
    @Test func removal() async throws {
        _ = try (1...3).compactMap { _ in try createPhoto().id }
        _ = try postManager.store(title: "New post",
                                  text: "Awesome food!",
                                  date: Date(),
                                  photoIDs: [3, 1, 2],
                                  mealPrice: 29)
        _ = try tagManager.assignTagsToPost(names: ["Tasty", "cheap"], postID: 1)
        
        #expect(try PhotoTable.get(db: connection, postID: 1).count == 3)
        #expect(try TagConnectionTable.get(db: connection, postID: 1).count == 2)
        
        try postManager.remove(id: 1)
        
        #expect(try PhotoTable.get(db: connection, postID: 1).count == 0)
        #expect(try TagConnectionTable.get(db: connection, postID: 1).count == 0)
    }
    
    @Test func amount() async throws {
        for i in 1...20 {
            _ = try postManager.store(title: "Post \(i)",
                                      text: "Content \(i)",
                                      date: Date(),
                                      photoIDs: [],
                                      mealPrice: 29)
        }
        #expect(try postManager.amount() == 20)
    }

    func createPhoto() throws -> Photo {
        let photo = Photo(postID: 0, 
                          filename: UUID().uuidString + ".jpg",
                          photoType: .mainPhoto)
        try PhotoTable.store(db: connection, photo)
        return photo
    }
}
