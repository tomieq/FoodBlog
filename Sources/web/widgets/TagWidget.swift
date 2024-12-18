//
//  TagWidget.swift
//  FoodBlog
//
//  Created by Tomasz on 15/11/2024.
//
import Template

class TagWidget {
    let template = Template.cached(relativePath: "templates/tag.widget.tpl.html")
    
    func html(tags: [Tag]) -> String {
        var output: String = ""
        let places = tags.filter{ $0.tagType == .restaurantName }
        let meals = tags.filter{ $0.tagType == .soup } + tags.filter{ $0.tagType == .mainMeal } + tags.filter{ $0.tagType == .mealSide } + tags.filter{ $0.tagType == .mealSalad }
        let other = tags.filter{ $0.tagType == .standard }
        
        output.append(addTags(places, with: "Miejsce \(TagType.restaurantName.icon)"))
        output.append(addTags(meals, with: "Dania \(TagType.mainMeal.icon)"))
        output.append(addTags(other, with: "Tagi"))
        
        return output
    }
    
    private func addTags(_ tags: [Tag], with label: String) -> String {
        if tags.isEmpty.not {
            template.reset()
            template["label"] = label
            for tag in tags {
                template.assign(["name": tag.name,
                                 "webLink": tag.webLink,
                                 "tagType": "\(tag.tagType)"], inNest: "tag")
            }
            return template.output
        }
        return ""
    }
}
