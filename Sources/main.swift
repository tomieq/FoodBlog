import Foundation
import BootstrapTemplate
import Template
import Swifter
import Dispatch


do {
    let server = HttpServer()
    server["/"] = { request, headers in
        let template = BootstrapTemplate()
        template.title = "Jem na mieście"
        template.addCSS(url: "css/style.css")
        template.body = Template.load(relativePath: "templates/body.tpl.html")
        return .ok(.html(template))
    }
    server["/admin"] = { request, headers in
        let template = BootstrapTemplate()
        template.title = "Jem na mieście"
        template.addCSS(url: "css/style.css")
        
        for multiPart in request.parseMultiPartFormData() {
            if let fileName = multiPart.fileName {
                let path = FileManager.default.currentDirectoryPath + "/volume/" + fileName
                FileManager.default.createFile(atPath: path, contents: Data(multiPart.body), attributes: nil)
            }
        }

        let adminTemplate = Template.load(relativePath: "templates/admin.tpl.html")
        adminTemplate["form"] = Template.cached(relativePath: "templates/uploadForm.tpl.html")
        
        template.body = adminTemplate
        return .ok(.html(template))
    }
    server.notFoundHandler = { request, responseHeaders in
        // serve Bootstrap static files
        if let filePath = BootstrapTemplate.absolutePath(for: request.path) {
            try HttpFileResponse.with(absolutePath: filePath)
        }
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
