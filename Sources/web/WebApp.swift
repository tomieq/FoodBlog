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
    
    var responseTemplate: BootstrapTemplate {
        let template = BootstrapTemplate()
        template.addCSS(url: "/css/style.css?v=2.8")
        template.addCSS(url: "/css/lightbox.min.css")
        template.addJS(url: "/js/lightbox.min.js")
        template.addJS(code: Template.cached(relativePath: "templates/securedRedirection.tpl.js"))
        return template
    }

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
        
        // welcome page
        server.get["/"] = { [unowned self] request, headers in
            if let cached = pageCache.page(request.path) {
                return .ok(.html(cached))
            }
            return .ok(.html(try pagedMainPostList(page: 0, path: request.path)))
        }
        // single post preview
        server.get["recenzje/:id/:seoLink"] = { [unowned self] request, _ in
            if let cached = pageCache.page(request.path) {
                return .ok(.html(cached))
            }
            guard let postID = request.pathParams.get("id")?.int64,
                  let post = try? postManager.get(id: postID) else {
                return .notFound(.html("No post"))
            }
            guard request.pathParams.get("seoLink") == post.title.seoLink else {
                return .movedPermanently("/recenzje/\(post.id!)/\(post.title.seoLink)")
            }
            return .ok(.html(try singlePostResponse(post: post)))
        }
        // paged history of posts
        server.get["/strona/:page"] = { [unowned self] request, headers in
            if let cached = pageCache.page(request.path) {
                return .ok(.html(cached))
            }
            let page = request.pathParams.get("page")?
                .replacingOccurrences(of: ".html", with: "").int ?? 0
            if request.path != Timeline.webLinkPaged(page) {
                return .movedPermanently(Timeline.webLinkPaged(page))
            }
            return .ok(.html(try pagedMainPostList(page: page, path: request.path)))
        }
        // legacy tag/seoName
        server.get["/tag/:seoName"] = { [unowned self] request, headers in
            guard let seoName = request.pathParams.get("seoName"),
                  let tag = try tagManager.get(seoName: seoName) else {
                return .notFound()
            }
            return .movedPermanently(tag.webLink)
        }
        // legacy tag/seoName/page
        server["/tag/:seoName/:page"] = { [unowned self] request, headers in
            guard let seoName = request.pathParams.get("seoName"),
                  let tag = try tagManager.get(seoName: seoName) else {
                return .notFound()
            }
            let page = request.pathParams.get("page")?.int ?? 0
            return .movedPermanently(tag.webLinkPaged(page))
        }
        server.get["/tagi/:seoName"] = { [unowned self] request, headers in
            if let cached = pageCache.page(request.path) {
                return .ok(.html(cached))
            }
            guard var seoName = request.pathParams.get("seoName")?.replacingOccurrences(of: ".html", with: "") else {
                return .notFound()
            }
            var page = 0
            if seoName.contains("-") {
                let parts = seoName.components(separatedBy: "-")
                page = parts.last?.int ?? 0
                seoName = parts.first ?? seoName
            }
            guard let tag = try tagManager.get(seoName: seoName) else {
                return .notFound()
            }
            return .ok(.html(try pagedTagPostList(tag: tag, page: page, path: request.path)))
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
        try server.start(8080)
    }
    
    private func pagedMainPostList(page: Int, path: String) throws -> CustomStringConvertible {
        let amount = try postManager.amount()
        let posts = try postManager.list(limit: postsPerPage, page: page)
        var previousPath: String? = nil
        var nextPath: String? = nil
        if page > 0 {
            previousPath = Timeline.webLinkPaged(page - 1)
        }
        if (page + 1) * postsPerPage < amount {
            nextPath = Timeline.webLinkPaged(page + 1)
        }

        return try previewListResponse(posts: posts,
                               path: path,
                               title: "Jem na mieście" + (page > 0 ? " - strona \(page)" : ""),
                               subtitle: "Kulinarne relacje<br>Smacznie? Tanio? Sprawdzam!",
                               previousPath: previousPath,
                               nextPath: nextPath)
    }
    
    private func pagedTagPostList(tag: Tag, page: Int, path: String) throws -> CustomStringConvertible {
        let postIDs = try tagManager.getPostIDs(tagID: tag.id!)
        let posts = try postManager.list(ids: postIDs, limit: postsPerPage, page: page)
        var previousPath: String? = nil
        var nextPath: String? = nil
        if page > 0 {
            previousPath = page == 1 ? tag.webLink : tag.webLinkPaged(page - 1)
        }
        if (page + 1) * postsPerPage < postIDs.count {
            nextPath = tag.webLinkPaged(page + 1)
        }

        return try previewListResponse(posts: posts,
                                       path: path,
                                       title: "\(tag.pageTitle) - \(tag.name)" + (page > 0 ? " - strona \(page)" : ""),
                                       subtitle: "\(tag.icon) \(tag.name)",
                                       tag: tag.pageTitle,
                                       previousPath: previousPath,
                                       nextPath: nextPath)
    }
    
    private func singlePostResponse(post: Post) throws -> CustomStringConvertible {
        let responseTemplate = self.responseTemplate
        responseTemplate.title = "\(post.title) - jemnamiescie.pl"
        let body = Template.cached(relativePath: "templates/body.tpl.html")
        let postTemplate = Template.cached(relativePath: "templates/post.tpl.html")
        
        var visiblePhotoIDs: [Int64] = []
        var visibleTagIDs: [Int64] = []
        
        for photo in try photoManager.get(postID: post.id!) {
            postTemplate.assign(["path": "/pics/\(photo.filename)"], inNest: "pic")
            visiblePhotoIDs.append(photo.id!)
        }
        postTemplate["title"] = post.title
        postTemplate["text"] = post.text
        postTemplate["date"] = post.date.readable
        postTemplate["dayOfWeek"] = post.date.dayOfWeek
        postTemplate["postLink"] = post.webLink
        let postTags = try tagManager.getTags(postID: post.id!)
        visibleTagIDs.append(contentsOf: postTags.compactMap{ $0.id })
        
        let tagWidget = TagWidget()
        postTemplate["tags"] = tagWidget.html(tags: postTags)
    
        if let price = post.mealPrice {
            postTemplate["mealPrice"] = "\(price.price) PLN"
        }
        body["content"] = postTemplate
        
        responseTemplate.body = body
    
        let meta = CacheMetaData(postIDs: [post.id!],
                                 photoIDs: visiblePhotoIDs.unique,
                                 tagIDs: visibleTagIDs.unique,
                                 isOnMainStory: false)
        pageCache.store(path: post.webLink, content: responseTemplate, meta: meta)
        
        return responseTemplate
    }
    
    
    
    private func previewListResponse(posts: [Post],
                                     path: String,
                                     title: String,
                                     subtitle: String,
                                     tag: String? = nil,
                                     previousPath: String?,
                                     nextPath: String?) throws -> CustomStringConvertible {
        let responseTemplate = self.responseTemplate
        responseTemplate.title = title
        let body = Template.cached(relativePath: "templates/body.tpl.html")
        let wrapperTemplate = Template.cached(relativePath: "templates/post.preview.wrapper.tpl.html")
        let previewTemplate = Template.cached(relativePath: "templates/post.preview.tpl.html")
        var visiblePhotoIDs: [Int64] = []
        var visibleTagIDs: [Int64] = []
        for post in posts {
            previewTemplate.reset()
            let mainPhotos = try photoManager.get(postID: post.id!)
                .filter { $0.photoType == .mainPhoto }
                .prefix(2)
            for photo in mainPhotos {
                previewTemplate.assign(["path": "/thumbs/\(photo.filename)"], inNest: "pic")
                visiblePhotoIDs.append(photo.id!)
            }
            let tags = try tagManager.getTags(postID: post.id!)
            visibleTagIDs.append(contentsOf: tags.compactMap{ $0.id })
            let previewText = PostSummaryWidget(post: post, tags: tags)
            previewTemplate["title"] = post.title
            previewTemplate["text"] = previewText.summary
            previewTemplate["postLink"] = post.webLink
            wrapperTemplate.assign(["preview": previewTemplate], inNest: "post")
        }
        body["content"] = wrapperTemplate
        body["subtitle"] = subtitle
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
        responseTemplate.body = body
        if posts.isEmpty.not {
            let meta = CacheMetaData(postIDs: posts.compactMap { $0.id },
                                     photoIDs: visiblePhotoIDs.unique,
                                     tagIDs: visibleTagIDs.unique,
                                     isOnMainStory: tag == nil)
            pageCache.store(path: path, content: responseTemplate, meta: meta)
        }
        return responseTemplate
    }
}
