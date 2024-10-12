//
//  Connection+extension.swift
//  FoodBlog
//
//  Created by Tomasz on 12/10/2024.
//
import SQLite

extension Connection {
    var userVersion: Int32 {
        get { return Int32(try! scalar("PRAGMA user_version") as! Int64) }
        set { try! run("PRAGMA user_version = \(newValue)") }
    }
}
