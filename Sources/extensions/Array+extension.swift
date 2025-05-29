//
//  Array+extension.swift
//
//
//  Created by Tomasz on 12/10/2024.
//

import Foundation
import SwiftExtensions

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

    func hasCommonElements(with other: [Element]) -> Bool {
        self.commonElements(with: other).isEmpty.not
    }
}
