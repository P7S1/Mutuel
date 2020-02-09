//
//  Post.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 12/28/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import Foundation
import FirebaseFirestore
import DeepDiff
import AVKit
struct Post{
    
    var photoURL : String
    
    var caption : String
    
    var publishDate : Date
    
    var creatorID : String
    
    var isVideo : Bool = false
    
    var videoURL : String?
    
    var photoSize : CGSize
    
    var postID : String
    
    var user : Account?
    
    var commentsCount : Int
    
    var repostsCount : Int
    
    var hasQueriedForUser = false
    
    var naturalSize : CGSize
    
    init(document : DocumentSnapshot) {
        let data = document.data()
        
     photoURL = data?["photoURL"] as? String ?? ""
     caption = data?["caption"] as? String ?? ""
     let date = data?["publishDate"] as? Timestamp ?? Timestamp()
        publishDate = date.dateValue()
     creatorID = data?["creatorID"] as? String ?? ""
        isVideo = data?["isVideo"] as? Bool ?? false
        videoURL = data?["videoURL"] as? String
        repostsCount = data?["repostsCount"] as? Int ?? 0
        commentsCount = data?["commentsCount"] as? Int ?? 0
        
        let width = data?["width"] as? Int ?? 200
        let height = data?["height"] as? Int ?? 200
        
        naturalSize = CGSize(width: width, height: height)

        photoSize = CGSize(width: width, height: height)
        postID = document.documentID
    }
    
    init(photoURL : String, caption : String, publishDate : Date, creatorID : String, isVideo : Bool, videoURL : String?, photoSize : CGSize, postID : String) {
        self.photoURL = photoURL
        self.caption = caption
        self.publishDate = publishDate
        self.creatorID = creatorID
        self.isVideo = isVideo
        self.videoURL = videoURL
        self.photoSize = photoSize
        self.naturalSize = photoSize
        self.postID = postID
        self.commentsCount = 0
        self.repostsCount = 0
    }
    
}

extension Post : DatabaseRepresentation{
    
    var representation : [String : Any]{
        let rep : [String : Any] = ["photoURL": photoURL,
                                    "caption" : caption,
                                    "publishDate" : Timestamp(date: publishDate),
                                    "creatorID" : creatorID,
                                    "isVideo" : isVideo,
                                    "videoURL" : videoURL as Any,
                                    "width" : photoSize.width,
                                    "height" : photoSize.height]
        return rep
    }
    
}


extension Post : DiffAware{
    var diffId: UUID? {
        let id = UUID(uuidString: self.postID)
        return id
    }
    
    typealias DiffId = UUID?
    

    static func compareContent(_ a: Post, _ b: Post) -> Bool {
        return (a.postID == b.postID)
    }
    
}


extension Post : Equatable, Comparable{
    static func < (lhs: Post, rhs: Post) -> Bool {
        return lhs.publishDate < rhs.publishDate
    }
    
    
}
