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
    
    func assignTagsToPost(names: [String], postID: Int64) throws -> [Int64] {
        var tags = try TagTable.get(db: db, names: names)
        var changedTagIDs: [Int64] = []
        // create non existing tags
        let existingTagNames = tags.map{ $0.name }
        for name in names {
            if existingTagNames.contains(name).not {
                let tag = Tag(name: name, seoName: name.camelCase, tagType: .standard)
                try TagTable.store(db: db, tag)
                tags.append(tag)
                changedTagIDs.append(tag.id!)
            }
        }
        // remove connections to tags that were removed
        let tagIDs = tags.compactMap{ $0.id }
        let connections = try TagConnectionTable.get(db: db, postID: postID)
        let connectionsToUnassign = connections.filter { tagIDs.contains($0.tagID).not }
        changedTagIDs += connectionsToUnassign.map { $0.tagID }

        try TagConnectionTable.remove(db: db, ids: connectionsToUnassign.map { $0.id })

        let connectedTagIDs = connections.map { $0.tagID }
        for tag in tags {
            if connectedTagIDs.contains(tag.id!).not {
                try TagConnectionTable.store(db: db, tagID: tag.id!, postID: postID)
                changedTagIDs.append(tag.id!)
            }
        }
        return changedTagIDs
    }
    
    func getTags(postID: Int64) throws -> [Tag] {
        let tagIDs = try TagConnectionTable.get(db: db, postID: postID).map { $0.tagID }
        return try TagTable.get(db: db, ids: tagIDs)
    }

    func getPostIDs(tagID: Int64) throws -> [Int64] {
        try TagConnectionTable.get(db: db, tagID: tagID).map { $0.postID }
    }
    
    func get(seoName: String) throws -> Tag? {
        try TagTable.get(db: db, seoName: seoName)
    }
    
    func update(currentSeoName: String, tag updatedTag: Tag) throws -> Int64? {
        guard let currentTag = try? TagTable.get(db: db, seoName: currentSeoName) else {
            return nil
        }
        let tag = Tag(id: currentTag.id,
                      name: updatedTag.name,
                      seoName: updatedTag.name.camelCase,
                      tagType: updatedTag.tagType)
        try TagTable.store(db: db, tag)
        return tag.id
    }
    
    var all: [Tag] {
        get throws {
            try TagTable.all(db: db)
        }
    }
}
