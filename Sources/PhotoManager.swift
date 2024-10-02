//
//  PhotoManager.swift
//  FoodBlog
//
//  Created by Tomasz on 02/10/2024.
//
import Foundation
import SQLite
import SwiftGD

class PhotoManager {
    let db: Connection

    init(db: Connection) throws {
        self.db = db
        try FileManager.default.createDirectory(atPath: Volume.picsPath, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(atPath: Volume.thumbsPath, withIntermediateDirectories: true)
        try PhotoTable.create(db: db)
    }
    
    func store(picture: Data) throws -> Photo {
        let image = try Image(data: picture, as: .jpg)
        let name = (UUID().uuidString + ".jpg").lowercased().replacingOccurrences(of: "-", with: "")
        let photo = try PhotoTable.store(db: db,
                                         Photo(id: nil,
                                               postID: 0,
                                               filename: name))

        if image.size.width > 2048 {
            try image.resizedTo(width: 2048)?.export(as: .jpg(quality: 80)).write(to: photo.piclocation)
            print("Saved new file to \(photo.piclocation)")
        } else {
            try image.export(as: .jpg(quality: 80)).write(to: photo.piclocation)
            print("Saved new file to \(photo.piclocation)")
        }
        try image.resizedTo(width: 256)?.export(as: .jpg(quality: 90)).write(to: photo.thumblocation)
        print("Saved new file to \(photo.thumblocation)")
        return photo
    }
}
