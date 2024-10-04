//
//  PhotoManager.swift
//  FoodBlog
//
//  Created by Tomasz on 02/10/2024.
//
import Foundation
import SQLite
import SwiftGD

enum FlipDirection: String {
    case horizontal
    case vertical
    
    var gdDirection: Image.FlipMode {
        switch self {
        case .horizontal:
            .horizontal
        case .vertical:
            .vertical
        }
    }
}

struct PhotoManager {
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
        let photo = Photo(id: nil,
                          postID: 0,
                          filename: name)
        try PhotoTable.store(db: db, photo)

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
    
    func remove(photoID: Int64) throws {
        guard let photo = try PhotoTable.get(db: db, id: photoID) else {
            return
        }
        try PhotoTable.remove(db: db, id: photoID)
        try FileManager.default.removeItem(at: photo.piclocation)
        try FileManager.default.removeItem(at: photo.thumblocation)
    }
    
    func flip(photoID: Int64, direction: FlipDirection) throws {
        guard let photo = try PhotoTable.get(db: db, id: photoID) else {
            return
        }
        [photo.thumblocation, photo.piclocation].forEach { url in
            if let image = Image(url: url) {
                image.flip(direction.gdDirection)
                image.write(to: url, allowOverwrite: true)
            }
        }
        print("Flipped image id: \(photoID) \(direction)")
    }
}
