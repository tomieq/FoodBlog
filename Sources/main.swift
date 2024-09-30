import Foundation
import BootstrapTemplate
import Template
import Swifter
import SwiftGD
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
        
        let picsPath = Volume.path + "pics/"
        let thumbsPath = Volume.path + "thumbs/"
        try FileManager.default.createDirectory(atPath: picsPath, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(atPath: thumbsPath, withIntermediateDirectories: true)
        
        for multiPart in request.parseMultiPartFormData() {
            if let image = try? Image(data: Data(multiPart.body), as: .jpg) {
                let name = UUID().uuidString + ".jpg"
                let piclocation = URL(fileURLWithPath: picsPath + name)
                let thumblocation = URL(fileURLWithPath: thumbsPath + name)
                if image.size.width > 2048 {
                    image.resizedTo(width: 2048)?.write(to: piclocation)
                } else {
                    image.write(to: piclocation)
                }
                image.resizedTo(width: 256)?.write(to: thumblocation)
            }
        }

        let adminTemplate = Template.load(relativePath: "templates/admin.tpl.html")
        adminTemplate["form"] = Template.cached(relativePath: "templates/uploadForm.tpl.html")
        
        for name in try FileManager.default.contentsOfDirectory(atPath: thumbsPath) {
            adminTemplate.assign(["path": "thumbs/" + name], inNest: "pics")
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
