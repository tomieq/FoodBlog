//
//  Encodable+extension.swift
//  FoodBlog
//
//  Created by Tomasz on 02/10/2024.
//
import Foundation

extension Encodable {
    var json: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(self)
        return String(data: data, encoding: .utf8)?
            .replacingOccurrences(of: "\\/", with: "/") ?? "{}"
    }

    var data: Data {
        let encoder = JSONEncoder()
        return try! encoder.encode(self)
    }
}
