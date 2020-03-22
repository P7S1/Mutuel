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
    
    var isGIF : Bool
    
    var creatorDisplayName : String
    var creatorPhotoURL : String
    var creatorUsername : String
    
    var originalPostID : String
    var originalPublishDate : Date
    
    var originalCreatorID : String
    
    var isRepost : Bool
    
    var reposterUsername : String
    
    var challengeID : String
    
    var challengeTitle : String
    
    var hasChallenge : Bool
    
    var dayNumber : Int
    
    var challengeDayID : String
    
    var isPrivate : Bool
    
    var tags : [String]
    
    var document : DocumentSnapshot?
    
    var score : Double
    
    var isExplicit : Bool
    
    init(document : DocumentSnapshot) {
        let data = document.data()
     photoURL = data?["photoURL"] as? String ?? ""
     caption = data?["caption"] as? String ?? ""
     let date = data?["publishDate"] as? Timestamp ?? Timestamp()
        publishDate = date.dateValue()
        let creatorID = data?["creatorID"] as? String ?? ""
        self.creatorID = creatorID
        isVideo = data?["isVideo"] as? Bool ?? false
        isGIF = data?["isGIF"] as? Bool ?? false
        videoURL = data?["videoURL"] as? String
        
        let width = data?["width"] as? CGFloat ?? 200
        let height = data?["height"] as? CGFloat ?? 200

        photoSize = CGSize(width: width, height: height)
        postID = document.documentID
        
        creatorDisplayName = data?["creatorDisplayName"] as? String ?? ""
        creatorPhotoURL = data?["creatorPhotoURL"] as? String ?? ""
        creatorUsername = data?["creatorUsername"] as? String ?? ""
        self.isRepost = data?["isRepost"] as? Bool ?? false
        self.reposterUsername = data?["reposterUsername"] as? String ?? ""
        self.originalPostID = data?["postID"] as? String ?? document.documentID
        
        let originalPublishDate = data?["originalPublishDate"] as? Timestamp ?? Timestamp()
        self.originalPublishDate = originalPublishDate.dateValue()
        self.originalCreatorID = data?["originalCreatorID"] as? String ?? (creatorID)
        
        self.challengeID = data?["challengeID"] as? String ?? ""
        self.challengeTitle = data?["challengeTitle"] as? String ?? ""
        self.hasChallenge = data?["hasChallenge"] as? Bool ?? false
        self.dayNumber = data?["dayNumber"] as? Int ?? 0
        self.challengeDayID = data?["challengeDayID"] as? String ?? ""
        self.isPrivate = data?["isPrivate"] as? Bool ?? false
        self.tags = data?["tags"] as? [String] ?? [String]()
        self.score = data?["score"] as? Double ?? 0.0
        self.isExplicit = data?["isExplicit"] as? Bool ?? false
        self.document = document
        
    }
    
    init(photoURL : String, caption : String, publishDate : Date, creatorID : String, isVideo : Bool, videoURL : String?, photoSize : CGSize, postID : String, isGIF : Bool, challenge : Challenge?, challengeDay : ChallengeDay?, tags : [String]) {
        self.photoURL = photoURL
        self.caption = caption
        self.publishDate = publishDate
        self.creatorID = creatorID
        self.isVideo = isVideo
        self.videoURL = videoURL
        self.photoSize = photoSize
        self.postID = postID
        self.isGIF = isGIF
        self.creatorDisplayName = User.shared.name ?? ""
        self.creatorPhotoURL = User.shared.profileURL ?? ""
        self.creatorUsername = User.shared.username ?? ""
        self.isRepost = false
        self.reposterUsername = User.shared.username ?? ""
        self.originalPostID = postID
        self.originalPublishDate = publishDate
        self.originalCreatorID = User.shared.uid ?? ""
        
        self.challengeID = challenge?.id ?? "undefined"
        self.challengeTitle = challenge?.title ?? ""
        self.hasChallenge = challenge != nil
        self.dayNumber = challengeDay?.day ?? 0
        self.challengeDayID = challengeDay?.id ?? ""
        self.isPrivate = User.shared.isPrivate
        self.score = 0.0
        self.tags = tags
        self.isExplicit = false
    }
  
    init(post : Post) {
        self = post
        self.isRepost = true
        self.creatorID = User.shared.uid ?? ""
        self.reposterUsername = User.shared.username ?? ""
        self.postID  = "\(User.shared.uid ?? "")_\(post.originalPostID)"
        self.publishDate = Date()
        self.originalCreatorID = post.originalCreatorID
        self.isPrivate = User.shared.isPrivate
        
    }
    
}

extension Post : DatabaseRepresentation{
    
     var representation : [String : Any]{
        let rep : [String : Any] = ["photoURL": photoURL,
                                    "caption" : caption,
                                    "creatorID" : creatorID,
                                    "isVideo" : isVideo,
                                    "videoURL" : videoURL as Any,
                                    "width" : photoSize.width,
                                    "height" : photoSize.height,
                                    "isGIF" : self.isGIF,
                                    "creatorDisplayName" : self.creatorDisplayName,
                                    "creatorPhotoURL" : self.creatorPhotoURL,
                                    "creatorUsername" : self.creatorUsername,
                                    "isRepost" : self.isRepost,
                                    "postID" : self.originalPostID,
                                    "reposterUsername" : self.reposterUsername,
                                    "originalPublishDate" : self.originalPublishDate,
                                    "originalCreatorID" : self.originalCreatorID,
                                    "challengeID": self.challengeID,
                                    "challengeTitle": self.challengeTitle,
                                    "hasChallenge": self.hasChallenge,
                                    "dayNumber" : self.dayNumber,
                                    "challengeDayID" : self.challengeDayID,
                                    "isPrivate" : self.isPrivate,
                                    "tags" : self.tags,
                                    "score" : self.score,
                                    "isExplicit" : self.isExplicit]
        
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
