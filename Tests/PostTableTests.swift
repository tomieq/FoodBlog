//
//  PostTableTests.swift
//  FoodBlog
//
//  Created by Tomasz on 04/10/2024.
//
import Testing
import SQLite
import Foundation
@testable import FoodBlog

struct PostTableTests {
    @Test func store() async throws {
        let connection = try Connection(.inMemory)
        let date = Date()
        let post = Post(id: nil,
                        title: "Nice title",
                        text: "Eating out is awesome!",
                        date: date,
                        mealPrice: 32.0,
                        mealQuality: .average)
        try PostTable.create(db: connection)
        try PostTable.store(db: connection, post)
        let saved = try #require(try PostTable.get(db: connection, id: 1))
        #expect(saved.title == "Nice title")
        #expect(saved.text == "Eating out is awesome!")
        #expect(saved.mealPrice == 32)
        #expect(Calendar(identifier: .gregorian).isDate(date, equalTo: saved.date, toGranularity: .second))
    }
}
