//
//  Challenge.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/17/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import Foundation
import FirebaseFirestore
struct Challenge {
    var title : String
    var desc : String
    var photoURL : URL
    var startDate : Date
    var endDate : Date
    var color : UIColor
    var id : String
    
    var days : [ChallengeDay] = [ChallengeDay]()
    
    init(document : DocumentSnapshot) {
        let data = document.data()
        self.id = document.documentID
        self.title = data?["title"] as? String ?? ""
        self.desc = data?["desc"] as? String ?? ""
        let photoURL = data?["photoURL"] as? String ?? ""
        self.photoURL = URL(string : photoURL)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        let colorString = data?["color"] as? String ?? ""
        self.color = UIColor(hex: colorString)
        
        
        self.startDate = dateFormatter.date(from: data?["startDate"] as! String)!
        
        self.endDate = dateFormatter.date(from: data?["endDate"] as! String)!
        
        for i in 0...(endDate.interval(ofComponent: .day, fromDate: startDate)){
            let challenge = ChallengeDay(data: data ?? [String : Any](), day: i+1, startDate: self.startDate)
            days.append(challenge)
        }
        
    }
}
