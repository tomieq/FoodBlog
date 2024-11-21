//
//  BackupServer.swift
//  FoodBlog
//
//  Created by Tomasz on 11/10/2024.
//
import Foundation
import BootstrapTemplate
import Swifter

class BackupServer {
    init(server: HttpServer) {
        server.get["admin/makeBackup"] = { _, _ in
            DispatchQueue.global().async {
                let shell = Shell()
                let backupPath = Volume.path + "foodBlogBackup.zip"
                try? FileManager.default.removeItem(atPath: backupPath)
                let dbPath = Volume.path + "storage.db"
                shell.exec("rm foodBlogBackup.tar")
                print(shell.exec("COPYFILE_DISABLE=1 tar czvf foodBlogBackup.tar \(Volume.picsPath) \(Volume.thumbsPath) \(Volume.logsPath) \(dbPath)"))
            }
            return .ok(.js(JSCode.showInfo("Started generating backup")))
        }
        
        server.get["admin/foodBlogBackup.tar"] = { _, _ in
            try HttpFileResponse.with(absolutePath: "foodBlogBackup.tar", clientCache: .noCache)
            return .ok(.text("Backup does not exist. Generate it first"))
        }
    }
}
