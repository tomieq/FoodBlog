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
        try TagConnectionTable.create(db: db)
    }
    
    func assignTagsToPost(names: [String], postID: Int64) throws {
        var tags = try TagTable.get(db: db, names: names)
        // create non existing tags
        let existingTagNames = tags.map{ $0.name }
        for name in names {
            if existingTagNames.contains(name).not {
                let tag = Tag(name: name, seoName: name.seo)
                try TagTable.store(db: db, tag)
                tags.append(tag)
            }
        }
        // remove connections to tags that were removed
        let tagIDs = tags.compactMap{ $0.id }
        let connections = try TagConnectionTable.get(db: db, postID: postID)
        let connectionIDsToRemove = connections.filter { tagIDs.contains($0.tagID).not }.map { $0.id }

        try TagConnectionTable.remove(db: db, ids: connectionIDsToRemove)

        let connectedTagIDs = connections.map { $0.tagID }
        for tag in tags {
            if connectedTagIDs.contains(tag.id!).not {
                try TagConnectionTable.store(db: db, tagID: tag.id!, postID: postID)
            }
        }
    }
    
    func getTags(postID: Int64) throws -> [Tag] {
        let tagIDs = try TagConnectionTable.get(db: db, postID: postID).map { $0.tagID }
        return try TagTable.get(db: db, ids: tagIDs)
    }
    
    var all: [Tag] {
        get throws {
            try TagTable.all(db: db)
        }
    }
}
