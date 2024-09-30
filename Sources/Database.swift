//
//  Database.swift
//  FoodBlog
//
//  Created by Tomasz on 30/09/2024.
//

import SQLite

class Database {
    let db: Connection
    
    init() throws {
        self.db = try Connection(Volume.path + "storage.db")
    }
}
