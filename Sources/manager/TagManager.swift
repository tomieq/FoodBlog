//
//  TagManager.swift
//  FoodBlog
//
//  Created by Tomasz on 11/10/2024.
//
import SQLite
import Foundation

class TagManager {
    let db: Connection
    
    init(db: Connection) throws {
        self.db = db
        try TagTable.create(db: db)
        try TaggedPostTable.create(db: db)
    }
    
    func getAndcreateIfNeeded(names: [String]) throws -> [Tag] {
        var existing = try TagTable.get(db: db, names: names)
        let existingNames = existing.map{ $0.name }
        for name in names {
            if !existingNames.contains(name) {
                let tag = Tag(name: name, seoName: name.seo)
                try TagTable.store(db: db, tag)
                existing.append(tag)
            }
        }
        return existing
    }
}
