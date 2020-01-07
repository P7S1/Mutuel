//
//  Like.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 1/4/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import Foundation
import FirebaseFirestore

struct Like{
    var id : String
    var likedUser : String
    var likedComment : String
    var userThatLiked : String
    var date : Date
    
    init(document: DocumentSnapshot) {
        let data = document.data()
        id = data?["id"] as? String ?? ""
        likedUser = data?["likedUser"] as? String ?? ""
        likedComment = data?["likedComment"] as? String ?? ""
        userThatLiked = data?["userThatLiked"] as? String ?? ""
        let date = data?["date"] as? Timestamp
        self.date = date?.dateValue() ?? Date()
    }
    
    init(userThatLiked : Account, comment: Comment, documentID : String){
        id = documentID
        self.userThatLiked = userThatLiked.uid ?? ""
        likedUser = comment.creatorID
        likedComment = comment.commentID
        self.userThatLiked = User.shared.uid ?? ""
        date = Date()
    }
}

extension Like : DatabaseRepresentation{
    
    var representation : [String : Any]{
        let rep : [String : Any] = [
            "id":id,
            "likedUser":likedUser,
            "likedComment":likedComment,
            "userThatLiked":userThatLiked,
            "date":Timestamp(date: date)]
        return rep
    }
    
}
