//
//  Array+extension.swift
//
//
//  Created by Tomasz on 12/10/2024.
//

import Foundation

extension Array where Element: Equatable {
    var unique: [Element] {
        var uniqueValues: [Element] = []
        forEach { item in
            guard !uniqueValues.contains(item) else { return }
            uniqueValues.append(item)
        }
        return uniqueValues
    }
}

extension Array where Element: Hashable {
    func commonElements(with other: [Element]) -> [Element] {
        Array(Set(self).intersection(Set(other)))
    }

    func hasCommonElements(with other: [Element]) -> Bool {
        !Set(self).intersection(Set(other)).isEmpty
    }
}
