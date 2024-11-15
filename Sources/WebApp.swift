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
            let ip = request.headers.get("x-forwarded-for") ?? request.peerName ?? ""
            print("Request \(request.id) \(request.method) \(request.path) from \(ip)")
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
        let amount = try postManager.amount()
        let posts = try postManager.list(limit: postsPerPage, page: page)
        var previousPath: String? = nil
        var nextPath: String? = nil
        if page > 0 {
            previousPath = page == 1 ? "/" : "/strona/\(page - 1)"
        }
        if (page + 1) * postsPerPage < amount {
            nextPath = "/strona/\(page + 1)"
        }

        return try response(posts: posts,
                            path: path,
                            title: "Jem na mieście" + (page > 0 ? " - strona \(page)" : ""),
                            subtitle: "Kulinarne relacje<br>Smacznie? Tanio? Sprawdzam!",
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
        if (page + 1) * postsPerPage < postIDs.count {
            nextPath = "/tag/\(tag.seoName)/\(page + 1)"
        }

        return try response(posts: posts,
                            path: path,
                            title: "\(tag.pageTitle) - \(tag.name)" + (page > 0 ? " - strona \(page)" : ""),
                            subtitle: tag.pageTitle,
                            tag: "\(tag.icon) \(tag.name)",
                            previousPath: previousPath,
                            nextPath: nextPath)
    }
    
    private func response(posts: [Post],
                          path: String,
                          title: String,
                          subtitle: String,
                          tag: String? = nil,
                          previousPath: String?,
                          nextPath: String?) throws -> CustomStringConvertible {
        let template = BootstrapTemplate()
        template.title = title
        template.addCSS(url: "/css/style.css?v=2.5")
        template.addCSS(url: "/css/lightbox.min.css")
        template.addJS(url: "/js/lightbox.min.js")
        template.addJS(code: Template.cached(relativePath: "templates/securedRedirection.tpl.js"))
        let body = Template.cached(relativePath: "templates/body.tpl.html")
        let postTemplate = Template.cached(relativePath: "templates/post.tpl.html")
        let tagWidget = TagWidget()
        var visiblePhotoIDs: [Int64] = []
        var visibleTagIDs: [Int64] = []
        for post in posts {
            postTemplate.reset()
            for photo in try photoManager.get(postID: post.id!) {
                postTemplate.assign(["path": "/pics/\(photo.filename)"], inNest: "pic")
                visiblePhotoIDs.append(photo.id!)
            }
            postTemplate["title"] = post.title
            postTemplate["text"] = post.text
            postTemplate["date"] = post.date.readable
            postTemplate["dayOfWeek"] = post.date.dayOfWeek
            postTemplate["postID"] = post.id
            let postTags = try tagManager.getTags(postID: post.id!)
            visibleTagIDs.append(contentsOf: postTags.compactMap{ $0.id })
            postTemplate["tags"] = tagWidget.html(tags: postTags)
            if let price = post.mealPrice {
                postTemplate["mealPrice"] = "\(price.price) PLN"
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
        body["subtitle"] = subtitle
        template.body = body
        if posts.isEmpty.not {
            let meta = CacheMetaData(postIDs: posts.compactMap { $0.id },
                                     photoIDs: visiblePhotoIDs.unique,
                                     tagIDs: visibleTagIDs.unique,
                                     isOnMainStory: tag == nil)
            pageCache.store(path: path, content: template, meta: meta)
        }
        return template
    }
}
