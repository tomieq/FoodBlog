//
//  SeoConverter.swift
//  FoodBlog
//
//  Created by Tomasz on 11/10/2024.
//
import Foundation

struct SeoConverter {
    
    private static let map = [ "ą": "a",
                               "Ą": "A",
                               "ś": "s",
                               "Ś": "S",
                               "ć": "c",
                               "Ć": "C",
                               "ł": "l",
                               "Ł": "L",
                               "ó": "o",
                               "Ó": "O",
                               "ż": "z",
                               "Ż": "Z",
                               "ź": "z",
                               "Ź": "Z",
                               "ę": "e",
                               "Ę": "E",
                               "ń": "n",
                               "Ń": "N"]
    static func asciiString(_ text: String) -> String {
        var ascii = text
        for (key, value) in Self.map where ascii.contains(key) {
            ascii = ascii.replacingOccurrences(of: key, with: value)
        }
        return ascii
    }
        
    static func makeCamel(_ text: String) -> String {
        guard !text.isEmpty else { return "" }
        let parts = text.components(separatedBy: .alphanumerics.inverted)
        let first = parts.first!
        let rest = parts.dropFirst().map { $0.uppercasingFirst }

        return ([first] + rest).joined()
    }
}

extension String {
    var seo: String {
        SeoConverter.asciiString(self).cameled
    }
    
    private var cameled: String {
        SeoConverter.makeCamel(self)
    }
}
