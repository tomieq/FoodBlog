//
//  SeoConverter.swift
//  FoodBlog
//
//  Created by Tomasz on 11/10/2024.
//
import Foundation

struct SeoConverter {
    static func asciiString(_ text: String) -> String {
        text
            .replacingOccurrences(of: "ą", with: "a")
            .replacingOccurrences(of: "Ą", with: "A")
            .replacingOccurrences(of: "ś", with: "s")
            .replacingOccurrences(of: "Ś", with: "S")
            .replacingOccurrences(of: "ć", with: "c")
            .replacingOccurrences(of: "Ć", with: "C")
            .replacingOccurrences(of: "ł", with: "l")
            .replacingOccurrences(of: "Ł", with: "L")
            .replacingOccurrences(of: "ó", with: "o")
            .replacingOccurrences(of: "Ó", with: "O")
            .replacingOccurrences(of: "ż", with: "z")
            .replacingOccurrences(of: "Ż", with: "Z")
            .replacingOccurrences(of: "ź", with: "z")
            .replacingOccurrences(of: "Ź", with: "Z")
            .replacingOccurrences(of: "ę", with: "e")
            .replacingOccurrences(of: "Ę", with: "E")
            .replacingOccurrences(of: "ń", with: "n")
            .replacingOccurrences(of: "Ń", with: "N")
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
