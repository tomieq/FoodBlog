//
//  Timeline.swift
//  FoodBlog
//
//  Created by Tomasz on 21/11/2024.
//

enum Timeline {
    static func webLinkPaged(_ page: Int) -> String {
        page == 0 ? "/" : "/strona/\(page).html"
    }
}
