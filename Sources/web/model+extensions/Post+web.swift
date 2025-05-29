//
//  Post+web.swift
//  FoodBlog
//
//  Created by Tomasz on 21/11/2024.
//

extension Post {
    var webLink: String {
        "/recenzje/\(self.id.or(0))/\(self.title.seoLink)"
    }
}
