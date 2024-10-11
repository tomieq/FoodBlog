//
//  AdminServer.swift
//  FoodBlog
//
//  Created by Tomasz on 11/10/2024.
//
import Foundation
import BootstrapTemplate
import Template
import Swifter
import SQLite

class AdminServer {

    let photoManager: PhotoManager
    let postManager: PostManager
    let tagManager: TagManager
    let pageCache: PageCache
    let digest: DigestAuthentication
    
    init(server: HttpServer,
         db: Connection,
         pageCache: PageCache,
         postManager: PostManager,
         tagManager: TagManager,
         adminPass: String,
         authToken: String) throws {

        self.photoManager = try PhotoManager(db: db)
        self.postManager = postManager
        self.tagManager = tagManager
        self.pageCache = pageCache

        self.digest = DigestAuthentication(realm: "Swifter Digest", credentialsProvider: { login in
            switch login {
            case "admin": adminPass
            default: nil
            }
        })

        server["/admin"] = { [unowned self] request, headers in
            if request.cookies.get("sid") != authToken {
                _ = try digest.authorizedUser(request)
                headers.setCookie(name: "sid", value: authToken, path: "/")
            }
            let moduleName = request.queryParams.get("module") ?? "photos"
            let template = BootstrapTemplate()
            template.title = "Admin"
            template.addCSS(url: "css/inputTags.css")
            template.addJS(url: "js/photoUpload.js")
            template.addJS(url: "js/inputTags.jquery.min.js")
            template.addJS(code: Template.cached(relativePath: "templates/admin.post.edit.tpl.js"))
            
            storePhotoIfNeeded(request)
            try deletePhotoIfNeeded(request)
            try flipPhotoIfNeeded(request)
            try publishPostIfNeeded(request)

            let adminTemplate = Template.cached(relativePath: "templates/admin.tpl.html")
            
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
                module["form"] = try editPostForm(post, photos)
            case "add.post":
                module = Template.cached(relativePath: "templates/admin.add.post.tpl.html")
                let photos = try PhotoTable.unowned(db: db)
                module["amount"] = photos.count
                assignThumbnails(photos, module, postID: 0)
                module["form"] = addPostForm(photos)
            case "backup":
                module = Template.cached(relativePath: "templates/admin.backup.tpl.html")
            default:
                module = Template.cached(relativePath: "templates/admin.photos.tpl.html")
                module["form"] = Template.cached(relativePath: "templates/uploadForm.tpl.html")
                let photos = try PhotoTable.get(db: db, last: 12)
                module["amount"] = photos.count
                assignThumbnails(photos, module, postID: 0)
            }
            adminTemplate["module"] = module

            template.body = adminTemplate
            return .ok(.html(template))
        }
        server.post["/admin/ajax_photo"] = { [unowned self] request, _ in
            guard let data = Data(base64Encoded: request.body.data) else {
                return .badRequest(.text("wrong data"))
            }
            print("Received \(data)")
            _ = try photoManager.store(picture: data)
            return .ok(.text("OK"))
        }
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
            self.pageCache.invalidate()
        }
    }
    
    private func publishPostIfNeeded(_ request: HttpRequest) throws {
        // add post
        if let title = request.formData.get("title"), let text = request.formData.get("text"),
           !text.isEmpty, !title.isEmpty, let tagList = request.formData.get("tags")?.split(separator: ","),
           let ids = request.formData.get("pictureIDs"), let dateString = request.formData.get("date"),
           let date = Date.make(from: dateString) {
            let photoIDs = ids.components(separatedBy: ",")
                .map{ $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .compactMap { Int64($0)}
            var updatedPost: Post!
            if let postID = request.formData.get("postID"), let id = Int64(postID), let post = try postManager.get(id: id) {
                updatedPost = try postManager.update(post, title: title, text: text, date: date, photoIDs: photoIDs)
            } else {
                updatedPost =  try postManager.store(title: title, text: text, date: date, photoIDs: photoIDs)
            }
            let tagNames = tagList.map { "\($0)".trimmingCharacters(in: .whitespacesAndNewlines) }
            try tagManager.assignTagsToPost(names: tagNames, postID: updatedPost.id!)
            pageCache.invalidate()
        }
    }
    
    private func deletePhotoIfNeeded(_ request: HttpRequest) throws {
        // delete image
        if let deleteID = request.queryParams.get("deleteID"), let id = Int64(deleteID) {
            try photoManager.remove(photoID: id)
            pageCache.invalidate()
        }
    }
    
    private func storePhotoIfNeeded(_ request: HttpRequest) {
        for multiPart in request.parseMultiPartFormData() where multiPart.fileName != nil {
            print("Received \(multiPart.body.count) bytes")
            _ = try? photoManager.store(picture: Data(multiPart.body))
            pageCache.invalidate()
        }
    }
    
    private func editPostForm(_ post: Post, _ photos: [Photo]) throws -> Form {
        let form = Form(url: "/admin", method: "POST")
        form.addInputText(name: "title", label: "Tytuł posta", value: post.title)
        form.addTextarea(name: "text", label: "Treść", value: post.text, rows: 10)
        form.addInputText(name: "pictureIDs", label: "ID zdjęć oddzielone przecinkami", value: photos.map{ "\($0.id!)" }.joined(separator: ","))
        form.addInputText(name: "date", label: "Data", value: post.date.readable)
        let tags = try tagManager.getTags(postID: post.id!)
        form.addInputText(name: "tags", label: "Tagi", value: tags.map { $0.name }.joined(separator: ","))
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
        form.addInputText(name: "tags", label: "Tagi", value: "")
        form.addSubmit(name: "add", label: "Opublikuj", style: .success)
        return form
    }
}
