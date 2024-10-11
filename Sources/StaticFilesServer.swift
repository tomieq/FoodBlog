//
//  StaticFilesServer.swift
//  FoodBlog
//
//  Created by Tomasz on 11/10/2024.
//
import Foundation
import BootstrapTemplate
import Template
import Swifter

class StaticFilesServer {

    init(server: HttpServer) {
        server.notFoundHandler = { request, responseHeaders in
            // serve Bootstrap static files
            if let filePath = BootstrapTemplate.absolutePath(for: request.path) {
                try HttpFileResponse.with(absolutePath: filePath, clientCache: .days(7))
            }
            try HttpFileResponse.with(absolutePath: Volume.path + request.path, clientCache: .days(7))

            let resourcePath = Resource().absolutePath(for: request.path)
            try HttpFileResponse.with(absolutePath: resourcePath, clientCache: .days(7))
            return .notFound()
        }
    }
}
