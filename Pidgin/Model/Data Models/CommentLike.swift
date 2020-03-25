//
//  CommentLike.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/25/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import Foundation
import FirebaseFirestore
class CommentLike {
    
    var userID : String
    var creationDate : Timestamp
    var commentID : String
    var username : String
    
    init(document : DocumentSnapshot) {
        let data = document.data()
        
        self.userID = data?["userID"] as? String ?? ""
        self.creationDate = data?["creationDate"] as? Timestamp ?? Timestamp()
        self.commentID = data?["commentID"] as? String ?? ""
        self.username = data?["username"] as? String ?? ""
    }
    
    init(commentID : String) {
        userID = User.shared.uid!
        creationDate = Timestamp(date:Date())
        self.commentID = commentID
        self.username = User.shared.username!
    }
    
}

extension CommentLike : DatabaseRepresentation {
    var representation: [String : Any] {
        return ["userID": self.userID,
                   "creationDate": self.creationDate,
                   "commentID": self.commentID,
                   "username": self.username]
    }
}
