//
//  SeoConverterTests.swift
//  FoodBlog
//
//  Created by Tomasz on 11/10/2024.
//

import Testing
import Swifter
import Foundation
@testable import FoodBlog

struct SeoConverterTests {
    @Test func check() async throws {
        #expect("ćma".camelCase == "cma")
        #expect("Łódź".camelCase == "Lodz")
        #expect("ta Łódź".camelCase == "taLodz")
        #expect("Ta Łódź".camelCase == "TaLodz")
        #expect("the camel".camelCase == "theCamel")
        #expect("".camelCase == "")
    }
}
