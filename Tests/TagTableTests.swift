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
                               Tag(name: "Łódź", nameEaten: "Łódź", seoName: "Lodz", tagType: .restaurantName))
        let saved = try TagTable.get(db: connection, names: ["Łódź"])
        #expect(saved.count == 1)
        #expect(saved.first?.seoName == "Lodz")
        #expect(saved.first?.tagType == .restaurantName)
    }
    
    @Test func findByNames() async throws {
        let connection = try Connection(.inMemory)
        try TagTable.create(db: connection)
        _ = try TagTable.store(db: connection,
                               Tag(name: "Łódź", nameEaten: "Łódź", seoName: "Lodz", tagType: .mealName))
        _ = try TagTable.store(db: connection,
                               Tag(name: "Warszawa", nameEaten: "Warszawa", seoName: "Warszawa", tagType: .mealName))
        let saved = try TagTable.get(db: connection, names: ["Łódź", "Warszawa"])
        #expect(saved.count == 2)
        #expect(saved.first?.tagType == .mealName)
    }

}
