//
//  EditPhotoTypeWidget.swift
//  FoodBlog
//
//  Created by Tomasz on 21/11/2024.
//
import Template

enum EditPhotoTypeWidget {
    static func form(photo: Photo) -> Template {
        let template = Template.cached(relativePath: "templates/admin.edit.photoType.tpl.html")
        for photoType in PhotoType.allCases {
            template.assign(["value": photoType.rawValue,
                             "name": "\(photoType)",
                             "selected": photoType == photo.photoType ? "selected=selected" : ""
                            ], inNest: "photoType")
        }
        template["photoID"] = photo.id
        return template
    }
}
