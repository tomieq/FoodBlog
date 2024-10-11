//
//  PageCache.swift
//  
//
//  Created by Tomasz on 10/10/2024.
//

import Foundation

class PageCache {
    let dispatchQueue = DispatchQueue(label: "cache", attributes: .concurrent)
    private var cache: [String: String] = [:]
    
    func page(_ path: String) -> String? {
        dispatchQueue.sync {
            cache[path]
        }
    }

    func invalidate() {
        dispatchQueue.sync(flags: .barrier) {
            cache = [:]
        }
        
    }
    
    func store(path: String, content: CustomStringConvertible) {
        dispatchQueue.sync(flags: .barrier) {
            cache[path] = content.description
        }
    }
}
