//
//  FileLogger.swift
//  FoodBlog
//
//  Created by Tomasz on 18/11/2024.
//
import Foundation


final class FileLogger {
    nonisolated(unsafe) static let shared = FileLogger()
    
    let queue = DispatchQueue(label: "log.write.queue")
    var filePath = ""
    var fileHandle: FileHandle?
    
    var desiredFilePath: String {
        "\(Volume.logsPath)/access.\(Date().readable).log"
    }
    
    init() {
        if FileManager.default.fileExists(atPath: Volume.logsPath).not {
            try? FileManager.default.createDirectory(atPath: Volume.logsPath, withIntermediateDirectories: true)
        }
    }
    
    deinit {
        fileHandle?.closeFile()
    }
    
    func openFileHandleIfNeeded() {
        if filePath == desiredFilePath {
            return
        }
        filePath = desiredFilePath
        if FileManager.default.fileExists(atPath: filePath).not {
            FileManager.default.createFile(atPath: filePath,  contents:Data("".utf8), attributes: nil)
        }
        fileHandle = FileHandle(forWritingAtPath: filePath)
        fileHandle?.seekToEndOfFile()
    }
    
    func log(_ txt: String) {
        queue.async {
            if let data = txt.data(using: .utf8) {
                Self.shared.openFileHandleIfNeeded()
                Self.shared.fileHandle?.write(data)
            }
        }
    }
}
