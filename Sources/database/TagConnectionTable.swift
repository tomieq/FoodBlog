//
//  TagConnectionTable.swift
//  FoodBlog
//
//  Created by Tomasz on 11/10/2024.
//

@preconcurrency import SQLite
import Foundation

enum TagConnectionTable {
    static let table = Table("tagConnection")
    static let id = SQLite.Expression<Int64>("id")
    static let tagID = SQLite.Expression<Int64>("tagID")
    static let postID = SQLite.Expression<Int64>("postID")
}

extension TagConnectionTable {
    static func create(db: Connection) throws {
        try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(tagID)
            t.column(postID)
        })
        try db.run(table.createIndex(tagID, ifNotExists: true))
        try db.run(table.createIndex(postID, ifNotExists: true))
    }
    
    static func store(db: Connection, tagID: Int64, postID: Int64) throws {
            try db.run(table.insert(
                Self.tagID <- tagID,
                Self.postID <- postID
            ))
            print("Created connection between tag(\(tagID)) and post(\(postID))")
    }
    
    static func get(db: Connection, postID: Int64) throws -> [TagConnection] {
        var result: [TagConnection] = []
        for row in try db.prepare(table.filter(Self.postID == postID)) {
            result.append(TagConnection(id: row[Self.id],
                                     postID: row[Self.postID],
                                     tagID: row[Self.tagID]))
        }
        return result
    }
    
    static func remove(db: Connection, ids: [Int64]) throws {
        guard ids.isEmpty.not else { return }
        try db.run(table.filter(ids.contains(Self.id)).delete())
    }
}
