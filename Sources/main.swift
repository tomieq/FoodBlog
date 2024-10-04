import Foundation
import SQLite
import BootstrapTemplate
import Template
import Swifter
import Dispatch


do {
    print("Open \(Volume.path + "storage.db")")
    let db = try Connection(Volume.path + "storage.db")
    let photoManager = try PhotoManager(db: db)
    let postManager = try PostManager(db: db)

    let server = HttpServer()
    server["/"] = { request, headers in
        let template = BootstrapTemplate()
        template.title = "Jem na mieście"
        template.addCSS(url: "css/style.css")
        let body = Template.cached(relativePath: "templates/body.tpl.html")
        let postTemplate = Template.cached(relativePath: "templates/post.tpl.html")
        
        for post in try postManager.list() {
            postTemplate.reset()
            for photo in post.photos {
                postTemplate.assign(["path": "/pics/\(photo.filename)"], inNest: "pic")
            }
            postTemplate["title"] = post.title
            postTemplate["text"] = post.text
            postTemplate["date"] = post.date.readable
            body.assign(["content": postTemplate], inNest: "post")
        }
        template.body = body
        return .ok(.html(template))
    }
    server["/admin"] = { request, headers in
        let digest = DigestAuthentication(realm: "Swifter Digest", credentialsProvider: { login in
            switch login {
            case "admin": "root"
            default: nil
            }
        })
        _ = try digest.authorizedUser(request)
        let template = BootstrapTemplate()
        template.title = "Jem na mieście"
        template.addCSS(url: "css/style.css")
        
        for multiPart in request.parseMultiPartFormData() where multiPart.fileName != nil {
            _ = try? photoManager.store(picture: Data(multiPart.body))
        }
        // delete image
        if let deleteID = request.queryParams.get("deleteID"), let id = Int64(deleteID) {
            try photoManager.remove(photoID: id)
        }
        // flip image
        if let flipID = request.queryParams.get("flip"), let id = Int64(flipID),
           let direction = request.queryParams.get("direction"), let flipDirection = FlipDirection(rawValue: direction) {
            try photoManager.flip(photoID: id, direction: flipDirection)
            return .movedTemporarily("/admin")
        }
        // add post
        if let title = request.formData.get("title"), let text = request.formData.get("text"),
           let ids = request.formData.get("pictureIDs"), let dateString = request.formData.get("date"),
           let date = Date.make(from: dateString) {
            let photoIDs = ids.components(separatedBy: ",")
                .map{ $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .compactMap { Int64($0)}
            _ = try postManager.store(title: title, text: text, date: date, photoIDs: photoIDs)
        }

        let adminTemplate = Template.cached(relativePath: "templates/admin.tpl.html")
        adminTemplate["form"] = Template.cached(relativePath: "templates/uploadForm.tpl.html")
        
        let photos = try PhotoTable.unowned(db: db)
        adminTemplate["amount"] = photos.count
        for photo in photos {
            adminTemplate.assign([
                "path": "thumbs/" + photo.filename,
                "id": photo.id!
            ], inNest: "pics")
        }
        
        let postForm = Form(url: "/admin", method: "POST")
        postForm.addInputText(name: "title", label: "Tytuł posta")
        postForm.addTextarea(name: "text", label: "Treść", rows: 10)
        postForm.addInputText(name: "pictureIDs", label: "ID zdjęć oddzielone przecinkami")
        postForm.addInputText(name: "date", label: "Data", value: Date().readable)
        postForm.addSubmit(name: "add", label: "Opublikuj", style: .success)
        adminTemplate["postForm"] = postForm
        template.addJS(code: Template.cached(relativePath: "templates/datePicker.tpl.js").output)
        template.body = adminTemplate
        return .ok(.html(template))
    }
    server.notFoundHandler = { request, responseHeaders in
        // serve Bootstrap static files
        if let filePath = BootstrapTemplate.absolutePath(for: request.path) {
            try HttpFileResponse.with(absolutePath: filePath)
        }
        try HttpFileResponse.with(absolutePath: Volume.path + request.path)

        let resourcePath = Resource().absolutePath(for: request.path)
        try HttpFileResponse.with(absolutePath: resourcePath)
        return .notFound()
    }
    server.middleware.append( { request, header in
        print("Request \(request.id) \(request.method) \(request.path) from \(request.peerName ?? "")")
        request.onFinished = { id, code, duration in
            print("Request \(id) finished with \(code) in \(String(format: "%.3f", duration)) seconds")
        }
        return nil
    })
    try server.start(8080)
    print("Server started")
    dispatchMain()
} catch {
    print(error)
}
