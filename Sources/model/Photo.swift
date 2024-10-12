//
//  Photo.swift
//  FoodBlog
//
//  Created by Tomasz on 30/09/2024.
//
import Foundation

class Photo: Codable {
    var id: Int64?
    var postID: Int64
    let filename: String
    var sequence: Int
    
    init(id: Int64? = nil, postID: Int64, filename: String, sequence: Int = 0) {
        self.id = id
        self.postID = postID
        self.filename = filename
        self.sequence = sequence
    }
}

extension Photo {
    var piclocation: URL {
        URL(fileURLWithPath: Volume.picsPath + filename)
    }
    var thumblocation: URL {
        URL(fileURLWithPath: Volume.thumbsPath + filename)
    }
    var renamed: Photo {
        Photo(id: self.id, postID: self.postID, filename: Self.randomName)
    }
}

extension Photo {
    static var randomName: String {
        (UUID().uuidString + ".jpg").lowercased().replacingOccurrences(of: "-", with: "")
    }
}
