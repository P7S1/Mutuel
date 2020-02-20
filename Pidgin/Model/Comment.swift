//
//  Comment.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 1/2/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import Foundation
import FirebaseFirestore
import DeepDiff
import GiphyCoreSDK
struct Comment{
    var photoURL : String
    
    var text : String
    
    var creatorID : String
    
    var postCreatorID : String
    
    var creatorUsername : String
    
    var commentID : String
    
    var creationDate : Date
    
    var repliesCount : Int
    
    var postID : String
    
    var likes : [String]
    
    var mediaID : String?
    
    var replyCreatorID : String?
    
    var aspectRatio : CGFloat
    
    init(text: String, commentID : String, post : Post, media : GPHMedia?, reply : Comment?) {
        self.text = text
        self.photoURL = User.shared.profileURL ?? ""
        self.commentID = commentID
        
        creatorID = User.shared.uid ?? ""
        creatorUsername = User.shared.username ?? ""
        self.repliesCount = 0
        self.creationDate = Date()
        self.postID = post.postID
        self.likes = [String]()
        self.mediaID = media?.id
        self.aspectRatio = media?.aspectRatio ?? 0
        self.postCreatorID = post.creatorID
        self.replyCreatorID = reply?.creatorID
    }
    
    init(document : DocumentSnapshot) {
        let data = document.data()
        
        self.text = data?["text"] as? String ?? ""
        self.creatorID = data?["creatorID"] as? String ?? ""
        self.creatorUsername = data?["creatorUsername"] as? String ?? ""
        self.commentID = data?["commentID"] as? String ?? ""
        self.photoURL = data?["photoURL"] as? String ?? ""
        self.repliesCount = data?["repliesCount"] as? Int ?? 0
        self.postID = data?["postID"] as? String ?? ""
        self.mediaID = data?["mediaID"] as? String
        self.replyCreatorID = data?["replyCreatorID"] as? String
        self.aspectRatio = data?["aspectRatio"] as? CGFloat ?? 0
        self.postCreatorID = data?["postCreatorID"] as? String ?? ""
        let timestamp = data?["creationDate"] as? Timestamp
        creationDate = timestamp?.dateValue() ?? Date()
        
        self.likes = data?["likes"] as? [String] ?? [String]()
        
        
    }
}

extension Comment : DatabaseRepresentation{
    
    var representation : [String : Any]{
        
        let rep : [String : Any] = [
            "photoURL":photoURL as Any,
            "text":text,
            "replyCreatorID":replyCreatorID,
            "creatorID":creatorID,
            "commentID":commentID,
            "creatorUsername":creatorUsername,
            "postID":self.postID,
            "likes":self.likes,
            "mediaID": self.mediaID as Any,
            "aspectRatio" : self.aspectRatio,
            "postCreatorID" : self.postCreatorID]
        return rep
    }
    
}

extension Comment : DiffAware{
    static func compareContent(_ a: Comment, _ b: Comment) -> Bool {
        return a == b
    }
    

    
    var diffId: UUID? {
        let id = UUID(uuidString: self.commentID)
        return id
    }
    
    typealias DiffId = UUID?

}


extension Comment : Comparable{
    
    static func < (lhs: Comment, rhs: Comment) -> Bool {
        return lhs.creationDate < rhs.creationDate
    }
    
  static func == (lhs: Comment, rhs: Comment) -> Bool {
    return lhs.commentID == rhs.commentID
  }
  
}

