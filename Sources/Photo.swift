//
//  Photo.swift
//  FoodBlog
//
//  Created by Tomasz on 30/09/2024.
//
import Foundation

struct Photo: Codable {
    let id: Int64?
    let postID: Int64
    let filename: String
}

extension Photo {
    var piclocation: URL {
        URL(fileURLWithPath: Volume.picsPath + filename)
    }
    var thumblocation: URL {
        URL(fileURLWithPath: Volume.thumbsPath + filename)
    }
}
