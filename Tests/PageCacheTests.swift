//
//  PageCacheTests.swift
//
//
//  Created by Tomasz on 12/10/2024.
//

import Testing
import Foundation
@testable import FoodBlog

struct PageCacheTests {
    @Test func invalidateByPostID() async throws {
        let sut = PageCache()
        sut.store(path: "mainPage", content: "welcome", meta: CacheMetaData(postIDs: [1, 2, 3],
                                                                            photoIDs: [10, 11, 12],
                                                                            tagIDs: [101, 102, 103],
                                                                            isOnMainStory: false))
        #expect(sut.page("mainPage") != nil)
        sut.invalidate(meta: CacheMetaData(postIDs: [5, 6],
                                           photoIDs: [],
                                           tagIDs: [],
                                           isOnMainStory: false))
        #expect(sut.page("mainPage") != nil)
        sut.invalidate(meta: CacheMetaData(postIDs: [2, 6],
                                           photoIDs: [],
                                           tagIDs: [],
                                           isOnMainStory: false))
        #expect(sut.page("mainPage") == nil)
    }
    
    @Test func invalidateByPhotoID() async throws {
        let sut = PageCache()
        sut.store(path: "mainPage", content: "welcome", meta: CacheMetaData(postIDs: [1, 2, 3],
                                                                            photoIDs: [10, 11, 12],
                                                                            tagIDs: [101, 102, 103],
                                                                            isOnMainStory: false))
        #expect(sut.page("mainPage") != nil)
        sut.invalidate(meta: CacheMetaData(postIDs: [],
                                           photoIDs: [13, 14, 15],
                                           tagIDs: [],
                                           isOnMainStory: false))
        #expect(sut.page("mainPage") != nil)
        sut.invalidate(meta: CacheMetaData(postIDs: [],
                                           photoIDs: [12, 13],
                                           tagIDs: [],
                                           isOnMainStory: false))
        #expect(sut.page("mainPage") == nil)
    }
    
    @Test func invalidateByTagID() async throws {
        let sut = PageCache()
        sut.store(path: "mainPage", content: "welcome", meta: CacheMetaData(postIDs: [1, 2, 3],
                                                                            photoIDs: [10, 11, 12],
                                                                            tagIDs: [101, 102, 103],
                                                                            isOnMainStory: false))
        #expect(sut.page("mainPage") != nil)
        sut.invalidate(meta: CacheMetaData(postIDs: [],
                                           photoIDs: [],
                                           tagIDs: [104, 105],
                                           isOnMainStory: false))
        #expect(sut.page("mainPage") != nil)
        sut.invalidate(meta: CacheMetaData(postIDs: [],
                                           photoIDs: [],
                                           tagIDs: [102],
                                           isOnMainStory: false))
        #expect(sut.page("mainPage") == nil)
    }
    
    // when new post is added, all paged main line need to be invalidated
    @Test func invalidateWhenIsOnMainStory() async throws {
        let sut = PageCache()
        sut.store(path: "mainPage", content: "welcome", meta: CacheMetaData(postIDs: [1, 2, 3],
                                                                            photoIDs: [10, 11, 12],
                                                                            tagIDs: [101, 102, 103],
                                                                            isOnMainStory: true))
        sut.store(path: "tagPage", content: "tags", meta: CacheMetaData(postIDs: [1, 2, 3],
                                                                        photoIDs: [10, 11, 12],
                                                                        tagIDs: [101, 102, 103],
                                                                        isOnMainStory: false))
        #expect(sut.page("mainPage") != nil)
        #expect(sut.page("tagPage") != nil)
        sut.invalidate(meta: CacheMetaData(postIDs: [9],
                                           photoIDs: [14],
                                           tagIDs: [104, 105],
                                           isOnMainStory: false))
        #expect(sut.page("mainPage") != nil)
        #expect(sut.page("tagPage") != nil)
        sut.invalidate(meta: CacheMetaData(postIDs: [9],
                                           photoIDs: [14],
                                           tagIDs: [104],
                                           isOnMainStory: true))
        #expect(sut.page("mainPage") == nil)
        #expect(sut.page("tagPage") != nil)
    }
}
