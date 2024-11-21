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
    
    func store(picture: Data, photoType: PhotoType) throws -> Photo {
        let image = try Image(data: picture, as: .jpg)
        let name = Photo.randomName
        let photo = Photo(id: nil,
                          postID: 0,
                          filename: name,
                          photoType: photoType)
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
    
    func update(photo: Photo) throws {
        try PhotoTable.store(db: db, photo)
    }
    
    func get(postID: Int64) throws -> [Photo] {
        try PhotoTable.get(db: db, postID: postID)
    }
    
    func get(photoID: Int64) throws -> Photo? {
        try PhotoTable.get(db: db, id: photoID)
    }
    
    func remove(photoID: Int64) throws -> Photo? {
        guard let photo = try PhotoTable.get(db: db, id: photoID) else {
            return nil
        }
        try PhotoTable.remove(db: db, id: photoID)
        try removePhisicalFiles(photo)
        return photo
    }
    
    func flip(photoID: Int64, direction: FlipDirection) throws {
        guard let photo = try PhotoTable.get(db: db, id: photoID) else {
            return
        }
        let renamed = photo.renamed
        try PhotoTable.store(db: db, renamed)
        func flip(original: URL, renamed: URL) {
            if let image = Image(url: original) {
                image.flip(direction.gdDirection)
                image.write(to: renamed, allowOverwrite: true)
            }
        }
        flip(original: photo.thumblocation, renamed: renamed.thumblocation)
        flip(original: photo.piclocation, renamed: renamed.piclocation)
        try removePhisicalFiles(photo)
        print("Flipped image id: \(photoID) \(direction)")
    }
    
    private func removePhisicalFiles(_ photo: Photo) throws {
        try FileManager.default.removeItem(at: photo.piclocation)
        try FileManager.default.removeItem(at: photo.thumblocation)
    }
}
