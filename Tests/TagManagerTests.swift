//
//  TagManagerTests.swift
//  FoodBlog
//
//  Created by Tomasz KUCHARSKI on 11/10/2024.
//

import Testing
import SQLite
@testable import FoodBlog

struct TagManagerTests {
    @Test func getAndCreate() async throws {
        let connection = try Connection(.inMemory)
        try TagTable.create(db: connection)
        let sut = try TagManager(db: connection)
        var tags = try sut.getAndcreateIfNeeded(names: ["Łódź", "Włocławek", "Paris"])
        #expect(tags.count == 3)
        tags = try sut.getAndcreateIfNeeded(names: ["Łódź", "Włocławek", "Paris"])
        #expect(tags.count == 3)
        let saved = try TagTable.get(db: connection, names: ["Łódź"])
        #expect(saved.count == 1)
        #expect(saved.first?.seoName == "Lodz")
    }

}
