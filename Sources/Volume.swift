//
//  Volume.swift
//  FoodBlog
//
//  Created by Tomasz KUCHARSKI on 30/09/2024.
//
import Foundation

enum Volume {
    static let path: String = FileManager.default.currentDirectoryPath + "/volume/"
    static let picsPath = Self.path + "pics/"
    static let thumbsPath = Self.path + "thumbs/"
}
