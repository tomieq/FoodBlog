//
//  WebApp.swift
//
//
//  Created by Tomasz on 05/10/2024.
//

import Foundation
import Swifter
import SQLite
import BootstrapTemplate
import Template
import Dispatch

class WebApp {
    let server = HttpServer()
    let db: Connection
    let postManager: PostManager
    let authToken = ProcessInfo.processInfo.environment["auth_token"] ?? UUID().uuidString
    let adminPass = ProcessInfo.processInfo.environment["admin_pass"] ?? UUID().uuidString
    var pageHtmlCache = PageCache()
    let staticServer: StaticFilesServer
    let adminServer: AdminServer
    let backupServer: BackupServer
    
    init(db: Connection) throws {
        
        self.db = db
        self.postManager = try PostManager(db: db)
        
        print("Auth token: \(authToken)")
        print("Admin pass: \(adminPass)")
        server.name = "ChickenServer 2.3"
        staticServer = StaticFilesServer(server: server)
        adminServer = try AdminServer(server: server,
                                      db: db,
                                      pageCache: pageHtmlCache,
                                      postManager: postManager,
                                      adminPass: adminPass,
                                      authToken: authToken)
        backupServer = BackupServer(server: server)
        
        server["/"] = { [unowned self] request, headers in
            let page = request.queryParams.get("page")?.int ?? 0
            return .ok(.html(try posts(page: page)))
        }
        server["/strona/:page"] = { [unowned self] request, headers in
            let page = request.pathParams.get("page")?.int ?? 0
            return .ok(.html(try posts(page: page)))
        }
        server["/index.html"] = { _, _ in
            .movedPermanently("/")
        }
        server.middleware.append( { request, header in
            print("Request \(request.id) \(request.method) \(request.path) from \(request.peerName ?? "")")
            request.onFinished = { id, code, duration in
                print("Request \(id) finished with \(code) in \(String(format: "%.3f", duration)) seconds")
            }
            return nil
        })
    }
    
    func start() throws {
        try server.start(8080)
    }
    
    private func posts(page: Int) throws -> CustomStringConvertible {
        if let cached = pageHtmlCache.page(page) {
            return cached
        }
        let template = BootstrapTemplate()
        template.title = "Jem na mieście" + (page > 0 ? " - strona \(page)" : "")
        template.addCSS(url: "/css/style.css")
        template.addCSS(url: "/css/lightbox.min.css")
        template.addJS(url: "/js/lightbox.min.js")
        template.addJS(code: Template.cached(relativePath: "templates/securedRedirection.tpl.js"))
        let body = Template.cached(relativePath: "templates/body.tpl.html")
        let postTemplate = Template.cached(relativePath: "templates/post.tpl.html")
        
        let posts = try postManager.list(limit: 4, page: page)
        for post in posts {
            postTemplate.reset()
            for photo in post.photos {
                postTemplate.assign(["path": "/pics/\(photo.filename)"], inNest: "pic")
            }
            postTemplate["title"] = post.title
            postTemplate["text"] = post.text
            postTemplate["date"] = post.date.readable
            postTemplate["postID"] = post.id
            body.assign(["content": postTemplate], inNest: "post")
        }
        if page > 0 {
            let url = page == 1 ? "/" : "/strona/\(page - 1)"
            body.assign(["url":url], inNest: "previous")
        }
        if posts.count > 0 {
            body.assign(["url":"/strona/\(page + 1)"], inNest: "next")
        }
        template.body = body
        pageHtmlCache.store(page: page, content: template)
        return template
    }
    
}
