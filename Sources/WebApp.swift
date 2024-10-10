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
    let photoManager: PhotoManager
    let postManager: PostManager
    let authToken = ProcessInfo.processInfo.environment["auth_token"] ?? UUID().uuidString
    let adminPass = ProcessInfo.processInfo.environment["admin_pass"] ?? UUID().uuidString
    
    lazy var digest = DigestAuthentication(realm: "Swifter Digest", credentialsProvider: { [unowned self] login in
        switch login {
        case "admin": adminPass
        default: nil
        }
    })
    
    init(db: Connection) throws {
        
        self.db = db
        self.photoManager = try PhotoManager(db: db)
        self.postManager = try PostManager(db: db)
        print("Auth token: \(authToken)")
        print("Admin pass: \(adminPass)")
        server.name = "ChickenServer 2.3"
        
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
        server["/admin"] = { [unowned self] request, headers in
            if request.cookies.get("sid") != authToken {
                _ = try digest.authorizedUser(request)
                headers.setCookie(name: "sid", value: authToken, path: "/")
            }
            let moduleName = request.queryParams.get("module") ?? "photos"
            let template = BootstrapTemplate()
            template.title = "Jem na mieście"
            template.addCSS(url: "css/sb-admin-2.min.css")
            
            storePhotoIfNeeded(request)
            try deletePhotoIfNeeded(request)
            try flipPhotoIfNeeded(request)
            try publishPostIfNeeded(request)

            let adminTemplate = Template.load(relativePath: "templates/admin.tpl.html")
            
            var module: Template!
            switch moduleName {
            case "posts":
                module = Template.cached(relativePath: "templates/admin.posts.tpl.html")
                for post in try PostTable.get(db: db, limit: 100, offset: 0) {
                    module.assign([
                        "id": post.id!,
                        "title": post.title
                    ], inNest: "post")
                }
            case "edit.post":
                module = Template.cached(relativePath: "templates/admin.edit.post.tpl.html")
                guard let post = try PostTable.get(db: db, id: request.queryParams.get("postID")?.int64 ?? 0) else {
                    return .movedTemporarily("/admin?module=posts")
                }
                let photos = try PhotoTable.get(db: db, postID: post.id!)
                module["amount"] = photos.count
                assignThumbnails(photos, module, postID: post.id!)
                module["form"] = editPostForm(post, photos)
            case "add.post":
                module = Template.cached(relativePath: "templates/admin.add.post.tpl.html")
                let photos = try PhotoTable.unowned(db: db)
                module["amount"] = photos.count
                assignThumbnails(photos, module, postID: 0)
                module["form"] = addPostForm(photos)
            default:
                module = Template.cached(relativePath: "templates/admin.photos.tpl.html")
                module["form"] = Template.cached(relativePath: "templates/uploadForm.tpl.html")
                let photos = try PhotoTable.get(db: db, last: 12)
                module["amount"] = photos.count
                assignThumbnails(photos, module, postID: 0)
            }
            adminTemplate["module"] = module

            template.addJS(code: Template.cached(relativePath: "templates/datePicker.tpl.js"))
            template.body = adminTemplate
            return .ok(.html(template))
        }
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
        return template
    }
    
    private func assignThumbnails(_ photos: [Photo], _ module: Template, postID: Int64) {
        for photo in photos {
            module.assign([
                "path": "thumbs/" + photo.filename,
                "id": photo.id!,
                "postID": postID
            ], inNest: "pics")
        }
    }
    
    private func flipPhotoIfNeeded(_ request: HttpRequest) throws {
        // flip photo
        if let flipID = request.queryParams.get("flip"), let id = Int64(flipID),
           let direction = request.queryParams.get("direction"), let flipDirection = FlipDirection(rawValue: direction) {
            try photoManager.flip(photoID: id, direction: flipDirection)
        }
    }
    
    private func publishPostIfNeeded(_ request: HttpRequest) throws {
        // add post
        if let title = request.formData.get("title"), let text = request.formData.get("text"),
           let ids = request.formData.get("pictureIDs"), let dateString = request.formData.get("date"),
           let date = Date.make(from: dateString) {
            let photoIDs = ids.components(separatedBy: ",")
                .map{ $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .compactMap { Int64($0)}
            if let postID = request.formData.get("postID"), let id = Int64(postID), let post = try PostTable.get(db: db, id: id) {
                _ = try postManager.update(post, title: title, text: text, date: date, photoIDs: photoIDs)
            } else {
                _ =  try postManager.store(title: title, text: text, date: date, photoIDs: photoIDs)
            }
        }
    }
    
    private func deletePhotoIfNeeded(_ request: HttpRequest) throws {
        // delete image
        if let deleteID = request.queryParams.get("deleteID"), let id = Int64(deleteID) {
            try photoManager.remove(photoID: id)
            //return .movedTemporarily("/admin?module=\(moduleName)")
        }
    }
    
    private func storePhotoIfNeeded(_ request: HttpRequest) {
        for multiPart in request.parseMultiPartFormData() where multiPart.fileName != nil {
            _ = try? photoManager.store(picture: Data(multiPart.body))
        }
    }
    
    private func editPostForm(_ post: Post, _ photos: [Photo]) -> Form {
        let form = Form(url: "/admin", method: "POST")
        form.addInputText(name: "title", label: "Tytuł posta", value: post.title)
        form.addTextarea(name: "text", label: "Treść", value: post.text, rows: 10)
        form.addInputText(name: "pictureIDs", label: "ID zdjęć oddzielone przecinkami", value: photos.map{ "\($0.id!)" }.joined(separator: ","))
        form.addInputText(name: "date", label: "Data", value: post.date.readable)
        form.addHidden(name: "postID", value: post.id!)
        form.addSubmit(name: "add", label: "Aktualizuj", style: .success)
        return form
    }
    
    private func addPostForm(_ photos: [Photo]) -> Form {
        let form = Form(url: "/admin", method: "POST")
        form.addInputText(name: "title", label: "Tytuł posta")
        form.addTextarea(name: "text", label: "Treść", rows: 10)
        form.addInputText(name: "pictureIDs", label: "ID zdjęć oddzielone przecinkami", value: photos.map{ "\($0.id!)" }.joined(separator: ","))
        form.addInputText(name: "date", label: "Data", value: Date().readable)
        form.addSubmit(name: "add", label: "Opublikuj", style: .success)
        return form
    }
}
