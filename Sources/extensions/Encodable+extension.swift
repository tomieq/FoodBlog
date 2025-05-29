//
//  Encodable+extension.swift
//  FoodBlog
//
//  Created by Tomasz on 02/10/2024.
//
import Foundation

extension Encodable {
    var data: Data {
        let encoder = JSONEncoder()
        return try! encoder.encode(self)
    }
}
