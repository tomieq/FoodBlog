//
//  PageCache.swift
//  
//
//  Created by Tomasz on 10/10/2024.
//

import Foundation

struct CacheMetaData {
    let postIDs: [Int64]
    let photoIDs: [Int64]
    let tagIDs: [Int64]
    let isOnMainStory: Bool
}

class PageCache {
    let dispatchQueue = DispatchQueue(label: "cache", attributes: .concurrent)
    private var cache: [String: String] = [:]
    private var metaData: [String: CacheMetaData] = [:]
    
    func page(_ path: String) -> String? {
        dispatchQueue.sync {
            cache[path]
        }
    }

    func invalidateAll() {
        dispatchQueue.sync(flags: .barrier) {
            cache = [:]
            metaData = [:]
            print("Invalidated all cache")
        }
    }
    
    func invalidate(meta: CacheMetaData) {
        _ = dispatchQueue.sync(flags: .barrier) {
            metaData.filter { data in
                data.value.postIDs.hasCommonElements(with: meta.postIDs) ||
                data.value.photoIDs.hasCommonElements(with: meta.photoIDs) ||
                data.value.tagIDs.hasCommonElements(with: meta.tagIDs) ||
                (meta.isOnMainStory && data.value.isOnMainStory)
            }
            .map { $0.key }
            .collect {
                $0.forEach { path in
                    cache[path] = nil
                    metaData[path] = nil
                }
                print("Invalidated cache for \($0.count) entries: [\($0)]")
            }
        }
    }
    
    func store(path: String, content: CustomStringConvertible, meta: CacheMetaData) {
        dispatchQueue.sync(flags: .barrier) {
            cache[path] = content.description
            metaData[path] = meta
            print("Cached page at \(path)")
        }
    }
}
