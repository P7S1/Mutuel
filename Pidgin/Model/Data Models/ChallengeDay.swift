//
//  ChallengeDay.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/17/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import Foundation


struct ChallengeDay{
    
    var id : String
    var day : Int
    var activity : String
    var isActive : Bool
    
    
    init(data: [String : Any], day : Int, startDate : Date) {
        self.day = day
        self.id = "\(data["id"] ?? "")_\(day)"
        self.activity = data[String(day-1)] as? String ?? ""
        isActive = Date() >= startDate
    }
}
