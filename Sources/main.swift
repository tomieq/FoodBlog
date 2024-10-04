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
    let server = HttpServer()
    server["/"] = { request, headers in
        let template = BootstrapTemplate()
        template.title = "Jem na mieście"
        template.addCSS(url: "css/style.css")
        let body = Template.load(relativePath: "templates/body.tpl.html")
        for photo in try PhotoTable.unowned(db: db) {
            body.assign(["path": "/pics/\(photo.filename)"], inNest: "pic")
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
        if let deleteID = request.queryParams.get("deleteID"), let id = Int64(deleteID) {
            try photoManager.remove(photoID: id)
        }

        let adminTemplate = Template.load(relativePath: "templates/admin.tpl.html")
        adminTemplate["form"] = Template.cached(relativePath: "templates/uploadForm.tpl.html")
        
        for photo in try PhotoTable.unowned(db: db) {
            adminTemplate.assign([
                "path": "thumbs/" + photo.filename,
                "id": photo.id!
            ], inNest: "pics")
        }
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
