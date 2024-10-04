//
//  PhotoTable.swift
//  FoodBlog
//
//  Created by Tomasz on 30/09/2024.
//
@preconcurrency import SQLite

enum PhotoTable {
    static let table = Table("photos")
    static let id = Expression<Int64>("id")
    static let postID = Expression<Int64>("postID")
    static let filename = Expression<String>("filename")
}

extension PhotoTable {
    static func create(db: Connection) throws {
        try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(postID, defaultValue: 0)
            t.column(filename)
        })
        try db.run(table.createIndex(postID, ifNotExists: true))
    }
    
    static func store(db: Connection, _ photo: Photo) throws -> Photo{
        if let rowID = photo.id {
            try db.run(table.filter(id == rowID).update(
                postID <- photo.postID,
                filename <- photo.filename
            ))
            print("Updated \(photo.json)")
            return photo
        } else {
            let id = try db.run(table.insert(
                postID <- photo.postID,
                filename <- photo.filename
            ))
            let photo = Photo(id: id,
                              postID: photo.postID,
                              filename: photo.filename)
            print("Inserted \(photo.json)")
            return photo
        }
    }
    
    static func photos(db: Connection, postID: Int64) throws -> [Photo] {
        var result: [Photo] = []
        for row in try db.prepare(table.filter(Self.postID == postID)) {
            result.append(Photo(id: row[id],
                                postID: row[Self.postID],
                                filename: row[filename]))
        }
        return result
    }
    
    static func photo(db: Connection, id: Int64) throws -> Photo? {
        if let row = try db.pluck(table.filter(Self.id == id)) {
            return Photo(id: row[Self.id],
                         postID: row[Self.postID],
                         filename: row[Self.filename])
        }
        return nil
    }
    
    static func unowned(db: Connection) throws -> [Photo] {
        try photos(db: db, postID: 0)
    }
    
    static func remove(db: Connection, id: Int64) throws {
        try db.run(table.filter(Self.id == id).delete())
    }
}
