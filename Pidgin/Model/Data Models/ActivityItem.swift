//
//  ActivityItem.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/7/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import Foundation
import FirebaseFirestore
import DeepDiff
struct ActivityItem {
    var senderUsername : String
    var senderID : String
    var type : ActivityType
    var recieverID : String
    var title : String
    var subtitle : String
    var date : Date
    var pointerID : String
    var id : String
    
    init(document : DocumentSnapshot) {
        let data = document.data()
        
        self.senderUsername = data?["senderUsername"] as? String ?? ""
        self.senderID = data?["senderID"] as? String ?? ""
        let text = data?["type"] as? String ?? ""
        self.type = ActivityType(text: text)
        self.recieverID = data?["recieverID"] as? String ?? ""
        self.title = data?["title"] as? String ?? ""
        self.subtitle = data?["subtitle"] as? String ?? ""
        self.pointerID = data?["pointerID"] as? String ?? "error"
        self.id = document.documentID
        
        let timestamp = data?["date"] as? Timestamp ?? Timestamp()
        self.date = timestamp.dateValue()
        
    }
    
    func getImage() -> UIImage{
        switch self.type {
        case .comment:
            return UIImage.init(systemName: "bubble.left")!
        case .commentReply:
            return UIImage.init(systemName: "bubble.left.and.bubble.right")!
        case .post:
            return UIImage.init(systemName: "arrow.2.squarepath")!
        case .follower:
            return UIImage.init(systemName: "person.fill")!
        default:
            return UIImage.init(systemName: "info.circle")!
        }
    }
    
    func getColor() -> UIColor{
       switch self.type {
        case .comment:
            return .systemPurple
        case .commentReply:
            return .systemIndigo
        case .post:
            return .systemGreen
        case .follower:
            return .systemBlue
        default:
            return .label
        }
    }
    
    func pushVC(vc: @escaping (UIViewController) -> Void ){
        switch self.type {
        case .comment, .commentReply, .post:
            
            let docRef = db.collection("users").document(recieverID).collection("posts").document(pointerID)
            
            docRef.getDocument { (snapshot, error) in
                    if error == nil{
                        let post = Post(document: snapshot!)
                    let storyboard = UIStoryboard(name: "Discover", bundle: nil)
                    let postVC = storyboard.instantiateViewController(identifier: "PostViewController") as! PostViewController
                    postVC.post = post
                    vc(postVC)
                    }else{
                        print(error!)
                    }
                
            }
        case .follower:
            
            let docRef = db.collection("users").document(pointerID)
            
            docRef.getDocument { (snapshot, error) in
                if error == nil{
                    let user = Account()
                    user.convertFromDocument(dictionary: snapshot!)
                    
                    let storyboard = UIStoryboard(name: "Discover", bundle: nil)
                    let userVC = storyboard.instantiateViewController(identifier: "ExploreViewController") as! ExploreViewController
                    userVC.isUserProfile = true
                    userVC.user = user
                    vc(userVC)
                }
            }
            
            
        default:
            return
        }
    }
}

extension ActivityItem : DiffAware{
    var diffId: UUID? {
        let id = UUID(uuidString: self.id)
        return id
    }
    
    typealias DiffId = UUID?
    

    static func compareContent(_ a: ActivityItem, _ b: ActivityItem) -> Bool {
        return (a.id == b.id)
        
    }
    
}


enum ActivityType {
    case comment
    case post
    case commentReply
    case info
    case follower
    
    init(text : String) {
        if text == "comment"{
            self = ActivityType.comment
        }else if text == "post"{
            self = ActivityType.post
        }else if text == "commentReply"{
            self = ActivityType.commentReply
        }else if text == "follower"{
            self = ActivityType.follower
        }else{
            self = ActivityType.info
        }
    }
}

