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
         photoManager: PhotoManager,
         tagManager: TagManager,
         adminPass: String,
         authToken: String) throws {

        self.photoManager = photoManager
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
                headers.setCookie(name: "sid", value: authToken, path: "/", cache: .days(7))
            }
            let moduleName = request.queryParams.get("module") ?? "welcome"
            let template = BootstrapTemplate()
            template.title = "Admin"
            template.addCSS(url: "css/tagify.css")
            template.addJS(url: "js/photoUpload.js?v=2")
            template.addJS(url: "js/tagify.js")
            
            func addFormJavaScript() throws {
                let jsTemplate = Template.cached(relativePath: "templates/admin.post.edit.tpl.js")
                jsTemplate["tagHistory"] = try tagManager.all.map{ "'\($0.name)'" }.joined(separator: ",")
                template.addJS(code: jsTemplate)
            }
            
            storePhotoIfNeeded(request)
            try deletePhotoIfNeeded(request)
            try deletePostfNeeded(request)
            try flipPhotoIfNeeded(request)
            try publishPostIfNeeded(request)
            try updateTagIfNeeded(request)

            let adminTemplate = Template.cached(relativePath: "templates/admin.tpl.html")
            
            var module: Template!
            switch moduleName {
            case "posts":
                module = Template.cached(relativePath: "templates/admin.posts.tpl.html")
                for post in try PostTable.get(db: db, limit: 100, offset: 0) {
                    module.assign([
                        "id": post.id!,
                        "title": post.title,
                        "date": post.date.readable
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
                try addFormJavaScript()
            case "add.post":
                module = Template.cached(relativePath: "templates/admin.add.post.tpl.html")
                let photos = try PhotoTable.unowned(db: db)
                module["amount"] = photos.count
                assignThumbnails(photos, module, postID: 0)
                module["form"] = addPostForm(photos)
                try addFormJavaScript()
            case "tags":
                module = Template.cached(relativePath: "templates/admin.tags.tpl.html")
                for tag in try tagManager.all {
                    module.assign([
                        "id": tag.id!,
                        "name": tag.name,
                        "icon": tag.icon,
                        "seoName": tag.seoName
                    ], inNest: "tag")
                }
            case "edit.tag":
                module = Template.cached(relativePath: "templates/admin.edit.tag.tpl.html")
                guard let tag = try  tagManager.get(seoName: request.queryParams.get("seoName") ?? "") else {
                    return .movedTemporarily("/admin?module=tags")
                }
                module["form"] = try editTagForm(tag)
            case "backup":
                module = Template.cached(relativePath: "templates/admin.backup.tpl.html")
            case "photos":
                module = Template.cached(relativePath: "templates/admin.photos.tpl.html")
                module["form"] = Template.cached(relativePath: "templates/uploadForm.tpl.html")
                let photos = try PhotoTable.get(db: db, last: 12)
                module["amount"] = photos.count
                assignThumbnails(photos, module, postID: 0)
            default:
                module = Template.cached(relativePath: "templates/admin.welcome.tpl.html")
            }
            adminTemplate["module"] = module

            template.body = adminTemplate
            return .ok(.html(template))
        }
        server.post["/admin/ajax_photo"] = { request, _ in
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
            self.pageCache.invalidate(meta: CacheMetaData(postIDs: [],
                                                          photoIDs: [id],
                                                          tagIDs: [],
                                                          isOnMainStory: false))
        }
    }
    
    private func publishPostIfNeeded(_ request: HttpRequest) throws {
        // add post
        if let title = request.formData.get("title"), let text = request.formData.get("text"),
           !text.isEmpty, !title.isEmpty, let tagList = request.formData.get("tags")?.split(separator: ","),
           let ids = request.formData.get("pictureIDs"), let dateString = request.formData.get("date"),
           let date = Date.make(from: dateString), let priceText = request.formData.get("price") {
            let photoIDs = ids.components(separatedBy: ",")
                .map{ $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .compactMap { Int64($0)}
            print(photoIDs)
            var updatedPost: Post!
            var isOnMainStory = false
            let price: Double? = priceText.isEmpty ? nil : Double(priceText)
            if let postID = request.formData.get("postID"), let id = Int64(postID), let post = try postManager.get(id: id) {
                updatedPost = try postManager.update(post, title: title, text: text, date: date, photoIDs: photoIDs, mealPrice: price)
            } else {
                updatedPost =  try postManager.store(title: title, text: text, date: date, photoIDs: photoIDs, mealPrice: price)
                isOnMainStory = true
            }
            let tagNames = tagList.map { "\($0)".trimmingCharacters(in: .whitespacesAndNewlines) }
            let changedTagIDs = try tagManager.assignTagsToPost(names: tagNames, postID: updatedPost.id!)
            pageCache.invalidate(meta: CacheMetaData(postIDs: [updatedPost.id!],
                                                     photoIDs: [],
                                                     tagIDs: changedTagIDs,
                                                     isOnMainStory: isOnMainStory))
        }
    }
    
    private func deletePhotoIfNeeded(_ request: HttpRequest) throws {
        // delete image
        if let deleteID = request.queryParams.get("deleteID"), let id = Int64(deleteID) {
            if let postID = try photoManager.remove(photoID: id)?.postID {
                pageCache.invalidate(meta: CacheMetaData(postIDs: [postID],
                                                         photoIDs: [],
                                                         tagIDs: [],
                                                         isOnMainStory: false))
            }
        }
    }
    
    private func deletePostfNeeded(_ request: HttpRequest) throws {
        // delete post
        if let deleteID = request.queryParams.get("removePostID"), let postID = Int64(deleteID) {
            let modifiedTags = try tagManager.getTags(postID: postID).compactMap { $0.id }
            try postManager.remove(id: postID)
            pageCache.invalidate(meta: CacheMetaData(postIDs: [postID],
                                                     photoIDs: [],
                                                     tagIDs: modifiedTags,
                                                     isOnMainStory: true))
        }
    }
    
    private func storePhotoIfNeeded(_ request: HttpRequest) {
        for multiPart in request.parseMultiPartFormData() where multiPart.fileName != nil {
            print("Received \(multiPart.body.count) bytes")
            _ = try? photoManager.store(picture: Data(multiPart.body))
        }
    }
    
    private func updateTagIfNeeded(_ request: HttpRequest) throws {
        if let tagSeoName = request.formData.get("seoName"),
           let name = request.formData.get("name"),
           let type = request.formData.get("type")?.int {

            let tag = Tag(name: name, seoName: name.seo, tagType: TagType(rawValue: type) ?? .standard)
            if let tagID = try tagManager.update(currentSeoName: tagSeoName, tag: tag) {
                pageCache.invalidate(meta: CacheMetaData(postIDs: [],
                                                         photoIDs: [],
                                                         tagIDs: [tagID],
                                                         isOnMainStory: false))
            }
        }
    }
    
    private func editPostForm(_ post: Post, _ photos: [Photo]) throws -> Form {
        let form = Form(url: "/admin", method: "POST")
        form.addInputText(name: "pictureIDs",
                          label: "ID zdjęć oddzielone przecinkami",
                          value: photos.map{ "\($0.id!)" }.joined(separator: ","),
                          attributes: ["inputmode": "numeric"])
        form.addInputText(name: "title", label: "Tytuł posta", value: post.title)
        form.addTextarea(name: "text", label: "Treść", rows: 10, value: post.text)
        form.addInputText(name: "price", label: "Cena", value: post.mealPrice?.price ?? "")
        form.addInputText(name: "date", label: "Data", value: post.date.readable)
        let tags = try tagManager.getTags(postID: post.id!)
        form.addInputText(name: "tags", label: "Tagi", value: tags.map { $0.name }.joined(separator: ","))
        form.addSeparator(txt: "Original tags: \(tags.map { $0.name }.joined(separator: ","))")
        form.addHidden(name: "postID", value: post.id!)
        form.addSubmit(name: "add", label: "Aktualizuj", style: .success)
        return form
    }
    
    private func addPostForm(_ photos: [Photo]) -> Form {
        let form = Form(url: "/admin", method: "POST")
        form.addInputText(name: "pictureIDs",
                          label: "ID zdjęć oddzielone przecinkami",
                          value: photos.map{ "\($0.id!)" }.joined(separator: ","),
                          attributes: ["inputmode": "numeric"])
        form.addInputText(name: "title", label: "Tytuł posta")
        form.addTextarea(name: "text", label: "Treść", rows: 10)
        form.addInputText(name: "price", label: "Cena", value: "")
        form.addInputText(name: "date", label: "Data", value: Date().readable)
        form.addInputText(name: "tags", label: "Tagi", value: "")
        form.addSubmit(name: "add", label: "Opublikuj", style: .success)
        return form
    }
    
    private func editTagForm(_ tag: Tag) throws -> Form {
        let form = Form(url: "/admin?module=tags", method: "POST")
        form.addInputText(name: "name", label: "Nazwa", value: tag.name)
        form.addRadio(name: "type", label: "Typ", options: TagType.allCases.map { FormRadioModel(label: "\($0)", value: "\($0.rawValue)") }, checked: "\(tag.tagType.rawValue)")
        form.addHidden(name: "seoName", value: tag.seoName)
        form.addSubmit(name: "add", label: "Aktualizuj", style: .success)
        return form
    }
}
