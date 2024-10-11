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
        #expect("ćma".seo == "cma")
        #expect("Łódź".seo == "Lodz")
        #expect("ta Łódź".seo == "taLodz")
        #expect("Ta Łódź".seo == "TaLodz")
        #expect("the camel".seo == "theCamel")
        #expect("".seo == "")
    }
}
