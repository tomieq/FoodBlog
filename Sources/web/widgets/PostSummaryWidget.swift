//
//  PostSummaryWidget.swift
//  FoodBlog
//
//  Created by Tomasz on 20/11/2024.
//
import Foundation

enum SummaryType {
    case html
    case text
}

class PostSummaryWidget {
    let post: Post
    let tags: [Tag]
    let summaryType: SummaryType
    
    init(post: Post, tags: [Tag], summaryType: SummaryType) {
        self.post = post
        self.tags = tags
        self.summaryType = summaryType
    }
    
    var summary: String {
        var txt = "\(post.date.onDayOfWeek.capitalizedSentence), \(post.date.monthDay) \(post.date.monthName) odwiedziłem "
        let places = tags.filter{ $0.tagType == .restaurantName }.map { $0.name }.joined(separator: "\" oraz \"")
        if places.isEmpty {
            txt.append("pewne miejsce.")
        } else {
            txt.append("\"\(places)\".")
        }
        if let price = post.mealPrice?.price {
            txt.append(" Za \(price) zł zjadłem ")
        } else {
            txt.append(" Zjadłem ")
        }
        let meals = tags.filter{ $0.tagType == .mealName }
            //.map { $0.name }
            .map {
                switch summaryType {
                case .html:
                    "<a href=\"\($0.webLink)\" class=\"btn btn-sm btn-tag-\($0.tagType)\">\($0.nameEaten)</a>"
                case .text:
                    $0.nameEaten
                }
            }
        if meals.isEmpty {
            txt.append(" bardzo ciekawe pozycje")
        } else if meals.count == 1 {
            txt.append(meals.joined())
        } else {
            let lastMeal = meals.last!
            let mealList = meals.prefix(meals.count - 1)
            txt.append(mealList.joined(separator: ", ") + " oraz " + lastMeal)
        }
        txt.append(".")
        return txt
    }
}

fileprivate extension Date {
    var monthDay: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.string(from: self)
    }
}

fileprivate extension Date {
    var monthName: String {
        let calendar = Calendar(identifier: .gregorian)
        let weekday = calendar.component(.month, from: self)
        
        switch weekday {
        case 1: return "stycznia"
        case 2: return "lutego"
        case 3: return "marca"
        case 4: return "kwietnia"
        case 5: return "maja"
        case 6: return "czerwca"
        case 7: return "lipca"
        case 8: return "sierpnia"
        case 9: return "września"
        case 10: return "października"
        case 11: return "listopada"
        case 12: return "grudnia"
        default: return "??"
        }
    }
}

fileprivate extension Date {
    var onDayOfWeek: String {
        let calendar = Calendar(identifier: .gregorian)
        let weekday = calendar.component(.weekday, from: self)
        
        switch weekday {
        case 1: return "w niedzielę"
        case 2: return "w poniedziałek"
        case 3: return "we wtorek"
        case 4: return "w środę"
        case 5: return "w czwartek"
        case 6: return "w piątek"
        case 7: return "w sobotę"
        default: return "w nieznany dzień"
        }
    }
}

fileprivate extension String {
    var capitalizedSentence: String {
        let firstLetter = self.prefix(1).capitalized
        let remainingLetters = self.dropFirst().lowercased()
        return firstLetter + remainingLetters
    }
}
