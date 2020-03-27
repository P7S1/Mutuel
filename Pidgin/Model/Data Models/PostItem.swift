//
//  PostItem.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/26/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import Foundation
import DeepDiff
class PostItem : DiffAware{
    
    var uniqueID = ""
    
    var diffId: UUID? {
        let id = UUID(uuidString: uniqueID)
        return id
    }
    
    typealias DiffId = UUID?
    
    static func compareContent(_ a: PostItem, _ b: PostItem) -> Bool {
        return a.uniqueID == b.uniqueID
    }
    
    init() {
        
    }
    
    
    
}
