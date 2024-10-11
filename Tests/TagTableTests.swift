//
//  TagTableTests.swift
//  FoodBlog
//
//  Created by Tomasz on 11/10/2024.
//

import Testing
import SQLite
@testable import FoodBlog

struct TagTableTests {
    @Test func findByName() async throws {
        let connection = try Connection(.inMemory)
        try TagTable.create(db: connection)
        _ = try TagTable.store(db: connection,
                               Tag(name: "Łódź", seoName: "Lodz"))
        let saved = try TagTable.get(db: connection, names: ["Łódź"])
        #expect(saved.count == 1)
        #expect(saved.first?.seoName == "Lodz")
    }
    
    @Test func findByNames() async throws {
        let connection = try Connection(.inMemory)
        try TagTable.create(db: connection)
        _ = try TagTable.store(db: connection,
                               Tag(name: "Łódź", seoName: "Lodz"))
        _ = try TagTable.store(db: connection,
                               Tag(name: "Warszawa", seoName: "Warszawa"))
        let saved = try TagTable.get(db: connection, names: ["Łódź", "Warszawa"])
        #expect(saved.count == 2)
    }

}
