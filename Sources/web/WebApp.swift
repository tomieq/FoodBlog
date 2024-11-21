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
    let postsPerPage = 6
    
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
        
        server.get["/"] = { [unowned self] request, headers in
            return .ok(.html(try posts(page: 0, path: request.path)))
        }
        server.get["recenzje/:id/:seoLink"] = { [unowned self] request, _ in
            guard let postID = request.pathParams.get("id")?.int64,
                  let post = try? postManager.get(id: postID) else {
                return .notFound(.html("No post"))
            }
            guard request.pathParams.get("seoLink") == post.title.seoLink else {
                return .movedPermanently("/recenzje/\(post.id!)/\(post.title.seoLink)")
            }
            return .ok(.html("post \(postID) \(request.pathParams.get("seoLink") ?? "none")"))
        }
        server.get["/strona/:page"] = { [unowned self] request, headers in
            let page = request.pathParams.get("page")?.int ?? 0
            return .ok(.html(try posts(page: page, path: request.path)))
        }
        server.get["/tag/:seoName"] = { [unowned self] request, headers in
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
            let method = request.method.rawValue
            let path = request.path
            let agent = request.headers.get("user-agent") ?? ""
            let referer = request.headers.get("referer") ?? ""
            
            request.onFinished = { summary in
                // awstat format: %host %time2 %method %url %uaquot %code %bytesd %refererquot
                FileLogger.shared.log("\(ip) \(Date().log) \(method) \(path) \"\(agent)\" \(summary.responseCode) \(summary.responseSizeInBytes) \"\(referer)\"\n")
            }
            return nil
        })
    }
    
    func start() throws {
        try server.start(8081)
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

        return try previewList(posts: posts,
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
        let postTemplate = Template.cached(relativePath: "templates/post.preview.tpl.html")
        let tagWidget = TagWidget()
        var visiblePhotoIDs: [Int64] = []
        var visibleTagIDs: [Int64] = []
        for post in posts {
            postTemplate.reset()
            for photo in try photoManager.get(postID: post.id!) {
                postTemplate.assign(["path": "/thumbs/\(photo.filename)"], inNest: "pic")
                visiblePhotoIDs.append(photo.id!)
            }
            postTemplate["title"] = post.title
            postTemplate["text"] = post.text
            postTemplate["postLink"] = post.webLink
//            let postTags = try tagManager.getTags(postID: post.id!)
//            visibleTagIDs.append(contentsOf: postTags.compactMap{ $0.id })
//            postTemplate["tags"] = tagWidget.html(tags: postTags)
//            if let price = post.mealPrice {
//                postTemplate["mealPrice"] = "\(price.price) PLN"
//            }
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
    
    
    
    private func previewList(posts: [Post],
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
        let wrapperTemplate = Template.cached(relativePath: "templates/post.preview.wrapper.tpl.html")
        let previewTemplate = Template.cached(relativePath: "templates/post.preview.tpl.html")
        let tagWidget = TagWidget()
        var visiblePhotoIDs: [Int64] = []
        var visibleTagIDs: [Int64] = []
        for post in posts {
            previewTemplate.reset()
            for photo in try photoManager.get(postID: post.id!).prefix(3) {
                previewTemplate.assign(["path": "/thumbs/\(photo.filename)"], inNest: "pic")
                visiblePhotoIDs.append(photo.id!)
            }
            let previewText = PostPreviewText(post: post, tags: try tagManager.getTags(postID: post.id!))
            previewTemplate["title"] = post.title
            previewTemplate["text"] = previewText.summary
            previewTemplate["postLink"] = post.webLink
            wrapperTemplate.assign(["preview": previewTemplate], inNest: "post")
        }
        body["content"] = wrapperTemplate
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
