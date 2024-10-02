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
        let saved = try PhotoTable.photos(db: connection, postID: 70)
        #expect(saved.count == 1)
        #expect(saved.first?.filename == "temp.jpg")
        #expect(saved.first?.postID == 70)
    }

    @Test func update() async throws {
        let connection = try Connection(.inMemory)
        try PhotoTable.create(db: connection)
        let photo = try PhotoTable.store(db: connection,
                                         Photo(id: nil,
                                               postID: 70,
                                               filename: "temp.jpg"))
        _ = try PhotoTable.store(db: connection,
                                 Photo(id: photo.id,
                                       postID: 70,
                                       filename: "temp3.jpg"))
        let saved = try PhotoTable.photos(db: connection, postID: 70)
        #expect(saved.count == 1)
        #expect(saved.first?.filename == "temp3.jpg")
        #expect(saved.first?.postID == 70)
    }
}
