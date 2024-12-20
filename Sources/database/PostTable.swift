//
//  PostTable.swift
//  FoodBlog
//
//  Created by Tomasz on 04/10/2024.
//

@preconcurrency import SQLite
import Foundation

enum PostTable {
    static let table = Table("posts")
    static let id = SQLite.Expression<Int64>("id")
    static let title = SQLite.Expression<String>("title")
    static let text = SQLite.Expression<String>("text")
    static let date = SQLite.Expression<Double>("date")
    static let mealPrice = SQLite.Expression<Double?>("mealPrice")
    static let mealQuality = SQLite.Expression<Int?>("mealQuality")
}

extension PostTable {
    static func create(db: Connection) throws {
        try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(title)
            t.column(text)
            t.column(date)
        })
        try db.run(table.createIndex(date, ifNotExists: true))
        _ = try? db.run(table.addColumn(mealPrice, defaultValue: nil))
        _ = try? db.run(table.addColumn(mealQuality, defaultValue: nil))
    }
    
    private static func mealQuality(from row: Row) -> MealQuality? {
        guard let rawValue = row[Self.mealQuality] else {
            return nil
        }
        return MealQuality(rawValue: rawValue)
    }
    
    static func store(db: Connection, _ post: Post) throws {
        if let rowID = post.id {
            try db.run(table.filter(id == rowID).update(
                title <- post.title,
                text <- post.text,
                date <- post.date.timeIntervalSince1970,
                mealPrice <- post.mealPrice,
                mealQuality <- post.mealQuality?.rawValue
            ))
            print("Updated \(post.json)")
        } else {
            let id = try db.run(table.insert(
                title <- post.title,
                text <- post.text,
                date <- post.date.timeIntervalSince1970,
                mealPrice <- post.mealPrice,
                mealQuality <- post.mealQuality?.rawValue
            ))
            post.id = id
            print("Inserted \(post.json)")
        }
    }

    static func amount(db: Connection) throws -> Int {
        try db.scalar(table.count)
    }

    static func get(db: Connection, id: Int64) throws -> Post? {
        if let row = try db.pluck(table.filter(Self.id == id)) {
            return Post(id: row[Self.id],
                        title: row[Self.title],
                        text: row[Self.text],
                        date: Date(timeIntervalSince1970: row[Self.date]),
                        mealPrice: row[Self.mealPrice],
                        mealQuality: Self.mealQuality(from: row))
        }
        return nil
    }
    
    static func get(db: Connection, limit: Int, offset: Int) throws -> [Post] {
        var result: [Post] = []
        for row in try db.prepare(table.order(Self.date.desc).limit(limit, offset: offset)) {
            result.append(Post(id: row[Self.id],
                               title: row[Self.title],
                               text: row[Self.text],
                               date: Date(timeIntervalSince1970: row[Self.date]),
                               mealPrice: row[Self.mealPrice],
                               mealQuality: Self.mealQuality(from: row)))
        }
        return result
    }
    
    static func get(db: Connection, ids: [Int64], limit: Int, offset: Int) throws -> [Post] {
        var result: [Post] = []
        for row in try db.prepare(table.filter(ids.contains(id)).order(Self.date.desc).limit(limit, offset: offset)) {
            result.append(Post(id: row[Self.id],
                               title: row[Self.title],
                               text: row[Self.text],
                               date: Date(timeIntervalSince1970: row[Self.date]),
                               mealPrice: row[Self.mealPrice],
                               mealQuality: Self.mealQuality(from: row)))
        }
        return result
    }
    
    static func remove(db: Connection, id: Int64) throws {
        try db.run(table.filter(Self.id == id).delete())
    }
}
