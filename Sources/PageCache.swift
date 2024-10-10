//
//  PageCache.swift
//  
//
//  Created by Tomasz on 10/10/2024.
//

import Foundation

class PageCache {
    let dispatchQueue = DispatchQueue(label: "cache", attributes: .concurrent)
    private var cache: [Int: String] = [:]
    
    func page(_ number: Int) -> String? {
        dispatchQueue.sync {
            cache[number]
        }
    }

    func invalidate() {
        dispatchQueue.sync(flags: .barrier) {
            cache = [:]
        }
        
    }
    
    func store(page: Int, content: CustomStringConvertible) {
        dispatchQueue.sync(flags: .barrier) {
            cache[page] = content.description
        }
    }
}
