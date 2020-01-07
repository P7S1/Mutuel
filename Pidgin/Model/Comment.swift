//
//  Comment.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 1/2/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import Foundation
import FirebaseFirestore
struct Comment{
    var photoURL : String?
    
    var text : String
    
    var creatorID : String
    
    var creatorUsername : String
    
    var creatorName : String
    
    var commentID : String
    
    var creationDate : Date
    
    init(text: String, photoURL : String?, commentID : String) {
        self.text = text
        self.photoURL = photoURL
        self.commentID = commentID
        
        creatorID = User.shared.uid ?? ""
        creatorUsername = User.shared.username ?? ""
        creatorName = User.shared.name ?? ""
    
        self.creationDate = Date()
    }
    
    init(document : DocumentSnapshot) {
        let data = document.data()
        
        self.text = data?["text"] as? String ?? ""
        self.photoURL = data?["photoURL"] as? String
        self.creatorID = data?["creatorID"] as? String ?? ""
        self.creatorUsername = data?["creatorID"] as? String ?? ""
        self.creatorName = data?["creatorName"] as? String ?? ""
        self.commentID = data?["commentID"] as? String ?? ""
        
        let timestamp = data?["creationDate"] as? Timestamp
        creationDate = timestamp?.dateValue() ?? Date()
    }
}

extension Comment : DatabaseRepresentation{
    
    var representation : [String : Any]{
        let rep : [String : Any] = [
            "photoURL":photoURL as Any,
            "text":text,
            "creatorID":creatorID,
            "creatorName":creatorName,
            "commentID":commentID,
            "creationDate": Timestamp(date: creationDate)]
        return rep
    }
    
}
