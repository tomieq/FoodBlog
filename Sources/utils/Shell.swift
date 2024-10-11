//
//  Shell.swift
//  FoodBlog
//
//  Created by Tomasz on 11/10/2024.
//
import Foundation

struct Shell {
    @discardableResult
    func exec(_ command: String) -> String {
        print("invoke ➡️   \(command)")
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/bash"
        task.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        return output.trimmingCharacters(in: .newlines)
    }
    
    @discardableResult
    func live(_ command: String) -> Int32 {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus
    }
}
