//
//  PhotoTableTests.swift
//  FoodBlog
//
//  Created by Tomasz on 02/10/2024.
//

import Testing
import SQLite
@testable import FoodBlog

struct PhotoTableTests {
    @Test func store() async throws {
        let connection = try Connection(.inMemory)
        try PhotoTable.create(db: connection)
        _ = try PhotoTable.store(db: connection,
                                 Photo(id: nil,
                                       postID: 70,
                                       filename: "temp.jpg"))
        _ = try PhotoTable.store(db: connection,
                                 Photo(id: nil,
                                       postID: 71,
                                       filename: "temp3.jpg"))
        let saved = try PhotoTable.get(db: connection, postID: 70)
        #expect(saved.count == 1)
        #expect(saved.first?.filename == "temp.jpg")
        #expect(saved.first?.postID == 70)
    }

    @Test func update() async throws {
        let connection = try Connection(.inMemory)
        try PhotoTable.create(db: connection)
        let photo = Photo(id: nil,
                          postID: 70,
                          filename: "temp.jpg")
        try PhotoTable.store(db: connection, photo)
        _ = try PhotoTable.store(db: connection,
                                 Photo(id: photo.id,
                                       postID: 70,
                                       filename: "temp3.jpg"))
        let saved = try PhotoTable.get(db: connection, postID: 70)
        #expect(saved.count == 1)
        #expect(saved.first?.filename == "temp3.jpg")
        #expect(saved.first?.postID == 70)
    }
    
    @Test func get() async throws {
        let connection = try Connection(.inMemory)
        try PhotoTable.create(db: connection)
        let photo = Photo(id: nil,
                          postID: 70,
                          filename: "temp.jpg")
        try PhotoTable.store(db: connection, photo)

        let saved = try PhotoTable.get(db: connection, id: photo.id!)
        #expect(saved?.filename == "temp.jpg")
        #expect(saved?.postID == 70)
    }
    
    @Test func getByIDs() async throws {
        let connection = try Connection(.inMemory)
        try PhotoTable.create(db: connection)
        let photo = Photo(id: nil,
                          postID: 70,
                          filename: "temp.jpg")
        try PhotoTable.store(db: connection, photo)
        try PhotoTable.store(db: connection, photo)

        let saved = try PhotoTable.get(db: connection, ids: [1, 2])
        #expect(saved.count == 1)
    }

    @Test func remove() async throws {
        let connection = try Connection(.inMemory)
        try PhotoTable.create(db: connection)
        _ = try PhotoTable.store(db: connection,
                                 Photo(id: nil,
                                       postID: 0,
                                       filename: "temp.jpg"))
        _ = try PhotoTable.store(db: connection,
                                 Photo(id: nil,
                                       postID: 0,
                                       filename: "temp3.jpg"))
        var saved = try PhotoTable.unowned(db: connection)
        #expect(saved.count == 2)
        try PhotoTable.remove(db: connection, id: 1)
        saved = try PhotoTable.unowned(db: connection)
        #expect(saved.count == 1)
        try PhotoTable.remove(db: connection, id: 2)
        saved = try PhotoTable.unowned(db: connection)
        #expect(saved.count == 0)
    }
}
