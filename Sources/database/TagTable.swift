//
//  TagTable.swift
//  FoodBlog
//
//  Created by Tomasz on 11/10/2024.
//

@preconcurrency import SQLite
import Foundation

enum TagTable {
    static let table = Table("tags")
    static let id = SQLite.Expression<Int64>("id")
    static let name = SQLite.Expression<String>("name")
    static let seoName = SQLite.Expression<String>("seoName")
}

extension TagTable {
    static func create(db: Connection) throws {
        try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(name)
            t.column(seoName)
        })
        try db.run(table.createIndex(name, ifNotExists: true))
        try db.run(table.createIndex(seoName, ifNotExists: true))
    }
    
    static func store(db: Connection, _ tag: Tag) throws {
        if let rowID = tag.id {
            try db.run(table.filter(id == rowID).update(
                name <- tag.name,
                seoName <- tag.seoName
            ))
            print("Updated tag \(tag.json)")
        } else {
            let id = try db.run(table.insert(
                name <- tag.name,
                seoName <- tag.seoName
            ))
            tag.id = id
            print("Inserted tag \(tag.json)")
        }
    }
    
    static func get(db: Connection, names: [String]) throws -> [Tag] {
        var result: [Tag] = []
        for row in try db.prepare(table.filter(names.contains(name))) {
            result.append(Tag(id: row[Self.id],
                              name: row[Self.name],
                              seoName: row[Self.seoName]))
        }
        return result
    }
    
    static func get(db: Connection, ids: [Int64]) throws -> [Tag] {
        var result: [Tag] = []
        for row in try db.prepare(table.filter(ids.contains(id))) {
            result.append(Tag(id: row[Self.id],
                              name: row[Self.name],
                              seoName: row[Self.seoName]))
        }
        return result
    }
    
    static func remove(db: Connection, id: Int64) throws {
        try db.run(table.filter(Self.id == id).delete())
    }
}
