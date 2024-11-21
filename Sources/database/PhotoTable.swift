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
    static let sequence = Expression<Int>("sequence")
    static let photoType = SQLite.Expression<Int>("type")
}

extension PhotoTable {
    static func create(db: Connection) throws {
        try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(postID, defaultValue: 0)
            t.column(filename)
        })
        try db.run(table.createIndex(postID, ifNotExists: true))
        
        // migration
        if db.userVersion == 0 {
            try db.run(table.addColumn(sequence, defaultValue: 0))
            try db.run(table.createIndex(sequence, ifNotExists: true))
            db.userVersion = 1
            print("Migrated DB to version 1")
        }
        _ = try? db.run(table.addColumn(photoType, defaultValue: PhotoType.mainPhoto.rawValue))
        try db.run(table.createIndex(photoType, ifNotExists: true))
    }
    
    static func store(db: Connection, _ photo: Photo) throws {
        if let rowID = photo.id {
            try db.run(table.filter(id == rowID).update(
                postID <- photo.postID,
                filename <- photo.filename,
                sequence <- photo.sequence,
                photoType <- photo.photoType.rawValue
            ))
            print("Updated \(photo.json)")
        } else {
            let id = try db.run(table.insert(
                postID <- photo.postID,
                filename <- photo.filename,
                sequence <- photo.sequence,
                photoType <- photo.photoType.rawValue
            ))
            photo.id = id
            print("Inserted \(photo.json)")
        }
    }
    
    static func get(db: Connection, postID: Int64) throws -> [Photo] {
        var result: [Photo] = []
        for row in try db.prepare(table.filter(Self.postID == postID).order(sequence.asc)) {
            result.append(Photo(id: row[id],
                                postID: row[Self.postID],
                                filename: row[filename],
                                photoType: PhotoType(rawValue: row[photoType]) ?? .mainPhoto,
                                sequence: row[sequence]))
        }
        return result
    }
    
    static func get(db: Connection, id: Int64) throws -> Photo? {
        if let row = try db.pluck(table.filter(Self.id == id)) {
            return Photo(id: row[Self.id],
                         postID: row[Self.postID],
                         filename: row[Self.filename],
                         photoType: PhotoType(rawValue: row[photoType]) ?? .mainPhoto,
                         sequence: row[sequence])
        }
        return nil
    }
    
    static func get(db: Connection, ids: [Int64]) throws -> [Photo] {
        var result: [Photo] = []
        for row in try db.prepare(table.filter(ids.contains(id))) {
            result.append(Photo(id: row[id],
                                postID: row[Self.postID],
                                filename: row[filename],
                                photoType: PhotoType(rawValue: row[photoType]) ?? .mainPhoto,
                                sequence: row[sequence]))
        }
        return result
    }
    
    static func get(db: Connection, last: Int) throws -> [Photo] {
        var result: [Photo] = []
        for row in try db.prepare(table.order(id.desc).limit(last)) {
            result.append(Photo(id: row[id],
                                postID: row[Self.postID],
                                filename: row[filename],
                                photoType: PhotoType(rawValue: row[photoType]) ?? .mainPhoto,
                                sequence: row[sequence]))
        }
        return result
    }
    
    static func unowned(db: Connection) throws -> [Photo] {
        try get(db: db, postID: 0)
    }
    
    static func remove(db: Connection, id: Int64) throws {
        try db.run(table.filter(Self.id == id).delete())
    }
}
