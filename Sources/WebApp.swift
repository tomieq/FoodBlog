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
    let photoManager: PhotoManager
    let tagManager: TagManager
    let authToken = ProcessInfo.processInfo.environment["auth_token"] ?? UUID().uuidString
    let adminPass = ProcessInfo.processInfo.environment["admin_pass"] ?? UUID().uuidString
    var pageCache = PageCache()
    let staticServer: StaticFilesServer
    let adminServer: AdminServer
    let backupServer: BackupServer
    let postsPerPage = 4
    
    init(db: Connection) throws {
        
        self.db = db
        self.postManager = try PostManager(db: db)
        self.photoManager = try PhotoManager(db: db)
        self.tagManager = try TagManager(db: db)
        
        print("Auth token: \(authToken)")
        print("Admin pass: \(adminPass)")
        server.name = "ChickenServer 2.3"
        staticServer = StaticFilesServer(server: server)
        adminServer = try AdminServer(server: server,
                                      db: db,
                                      pageCache: pageCache,
                                      postManager: postManager,
                                      photoManager: photoManager,
                                      tagManager: tagManager,
                                      adminPass: adminPass,
                                      authToken: authToken)
        backupServer = BackupServer(server: server)
        
        server["/"] = { [unowned self] request, headers in
            return .ok(.html(try posts(page: 0, path: request.path)))
        }
        server["/strona/:page"] = { [unowned self] request, headers in
            let page = request.pathParams.get("page")?.int ?? 0
            return .ok(.html(try posts(page: page, path: request.path)))
        }
        server["/tag/:seoName"] = { [unowned self] request, headers in
            guard let seoName = request.pathParams.get("seoName"),
                  let tag = try tagManager.get(seoName: seoName) else {
                return .notFound()
            }
            return .ok(.html(try posts(tag: tag, page: 0, path: request.path)))
        }
        server["/tag/:seoName/:page"] = { [unowned self] request, headers in
            guard let seoName = request.pathParams.get("seoName"),
                  let tag = try tagManager.get(seoName: seoName) else {
                return .notFound()
            }
            let page = request.pathParams.get("page")?.int ?? 0
            return .ok(.html(try posts(tag: tag, page: page, path: request.path)))
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
    
    private func posts(page: Int, path: String) throws -> CustomStringConvertible {
        if let cached = pageCache.page(path) {
            return cached
        }
        let posts = try postManager.list(limit: postsPerPage, page: page)
        var previousPath: String? = nil
        var nextPath: String? = nil
        if page > 0 {
            previousPath = page == 1 ? "/" : "/strona/\(page - 1)"
        }
        if posts.count == postsPerPage {
            nextPath = "/strona/\(page + 1)"
        }

        return try response(posts: posts,
                            path: path,
                            title: "Jem na mieście" + (page > 0 ? " - strona \(page)" : ""),
                            previousPath: previousPath,
                            nextPath: nextPath)
    }
    
    private func posts(tag: Tag, page: Int, path: String) throws -> CustomStringConvertible {
        if let cached = pageCache.page(path) {
            return cached
        }
        let postIDs = try tagManager.getPostIDs(tagID: tag.id!)
        let posts = try postManager.list(ids: postIDs, limit: postsPerPage, page: page)
        var previousPath: String? = nil
        var nextPath: String? = nil
        if page > 0 {
            previousPath = page == 1 ? "/tag/\(tag.seoName)" : "/tag/\(tag.seoName)/\(page - 1)"
        }
        if posts.count == postsPerPage {
            nextPath = "/tag/\(tag.seoName)/\(page + 1)"
        }

        return try response(posts: posts,
                            path: path,
                            title: "Jem na mieście - \(tag.name)" + (page > 0 ? " - strona \(page)" : ""),
                            tag: "#\(tag.name)",
                            previousPath: previousPath,
                            nextPath: nextPath)
    }
    
    private func response(posts: [Post],
                          path: String,
                          title: String,
                          tag: String? = nil,
                          previousPath: String?,
                          nextPath: String?) throws -> CustomStringConvertible {
        let template = BootstrapTemplate()
        template.title = title
        template.addCSS(url: "/css/style.css?v=3")
        template.addCSS(url: "/css/lightbox.min.css")
        template.addJS(url: "/js/lightbox.min.js")
        template.addJS(code: Template.cached(relativePath: "templates/securedRedirection.tpl.js"))
        let body = Template.cached(relativePath: "templates/body.tpl.html")
        let postTemplate = Template.cached(relativePath: "templates/post.tpl.html")
        
        for post in posts {
            postTemplate.reset()
            for photo in try photoManager.get(postID: post.id!) {
                postTemplate.assign(["path": "/pics/\(photo.filename)"], inNest: "pic")
            }
            postTemplate["title"] = post.title
            postTemplate["text"] = post.text
            postTemplate["date"] = post.date.readable
            postTemplate["postID"] = post.id
            try tagManager.getTags(postID: post.id!).forEach {
                postTemplate.assign($0, inNest: "tag")
            }
            body.assign(["content": postTemplate], inNest: "post")
        }
        if let previousPath = previousPath {
            body.assign(["url": previousPath], inNest: "previous")
        }
        if let nextPath = nextPath {
            body.assign(["url": nextPath], inNest: "next")
        }
        if let tag = tag {
            body.assign(["title": tag], inNest: "tag")
        }
        template.body = body
        if posts.isEmpty.not {
            pageCache.store(path: path, content: template)
        }
        return template
    }
}
