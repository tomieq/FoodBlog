//
//  TagManagerTests.swift
//  FoodBlog
//
//  Created by Tomasz KUCHARSKI on 11/10/2024.
//

import Testing
import SQLite
@testable import FoodBlog

struct TagManagerTests {
    @Test func assignTagsToPost() async throws {
        let connection = try Connection(.inMemory)
        try TagTable.create(db: connection)
        let sut = try TagManager(db: connection)
        
        // initial assigment
        try sut.assignTagsToPost(names: ["Łódź", "Włocławek", "Paris"], postID: 3)
        var saved = try sut.getTags(postID: 3)
        #expect(saved.count == 3)
        
        // update by deleting one
        try sut.assignTagsToPost(names: ["Łódź", "Włocławek"], postID: 3)
        saved = try sut.getTags(postID: 3)
        #expect(saved.count == 2)
        
        // update by adding one
        try sut.assignTagsToPost(names: ["Łódź", "Włocławek", "Berlin"], postID: 3)
        saved = try sut.getTags(postID: 3)
        #expect(saved.count == 3)
        
        // remove all tags
        try sut.assignTagsToPost(names: [], postID: 3)
        saved = try sut.getTags(postID: 3)
        #expect(saved.count == 0)
        
        // add some existing one
        try sut.assignTagsToPost(names: ["Włocławek"], postID: 3)
        saved = try sut.getTags(postID: 3)
        #expect(saved.count == 1)
    }

}
