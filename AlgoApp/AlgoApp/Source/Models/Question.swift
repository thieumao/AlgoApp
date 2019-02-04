//
//  Problem.swift
//  Scraper
//
//  Created by Huong Do on 1/29/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import RealmSwift

final class Question: Object {
    @objc dynamic var id = 0
    @objc dynamic var title = ""
    @objc dynamic var content = ""
    @objc dynamic var articleSlug = ""
    @objc dynamic var titleSlug = ""
    @objc dynamic var rawDifficultyLevel = 1
    
    @objc dynamic var topLiked = false
    @objc dynamic var topInterview = false
    @objc dynamic var saved = false
    
    @objc dynamic var read = false
    @objc dynamic var note = ""
    
    var tags = List<Tag>()
    var companies = List<Company>()
    
    var paidOnly = false
    var difficultyLevel: DifficultyLevel {
        return DifficultyLevel(rawValue: rawDifficultyLevel) ?? .easy
    }
    
    enum DifficultyLevel: Int {
        case easy = 1
        case medium = 2
        case hard = 3
        
        var title: String {
            switch self {
            case .easy: return "Easy"
            case .medium: return "Medium"
            case .hard: return "Hard"
            }
        }
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }

}
