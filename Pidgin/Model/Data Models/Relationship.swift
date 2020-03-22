//
//  Relationship.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 2/15/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import Foundation
import FirebaseFirestore
import DeepDiff
class Relationship {
    var followed : String
    var follower : String
    var isApproved : Bool
    
    var followedUsername : String
    var followedProfileURL : String
    
    var followerUsername : String
    var followerProfileURL : String
    
    var id : String
    
    var isFollowedBlocked : Bool
    
    init(document : DocumentSnapshot) {
        let data = document.data()
        followed = data?["followed"] as? String ?? ""
        follower = data?["follower"] as? String ?? ""
        isApproved = data?["isApproved"] as? Bool ?? false
        
        followedUsername = data?["followedUsername"] as? String ?? ""
        followedProfileURL = data?["followedProfileURL"] as? String ?? ""
        
        followerUsername = data?["followerUsername"] as? String ?? ""
        followerProfileURL = data?["followerProfileURL"] as? String ?? ""
        isFollowedBlocked = data?["isFollowedBlocked"] as? Bool ?? false
        
        self.id = document.documentID
    }
    
    init(followedUser : Account, id : String, isApproved : Bool) {
        follower = User.shared.uid ?? ""
        followerUsername = User.shared.username ?? ""
        followerProfileURL = User.shared.profileURL ?? ""
        
        followed = followedUser.uid ?? ""
        followedUsername = followedUser.username ?? ""
        followedProfileURL = followedUser.profileURL ?? ""
        self.id = id
        self.isApproved = isApproved
        self.isFollowedBlocked = false
    }
    
    func getFollowerAccount() -> Account{
        
        let account = Account()
        account.profileURL = self.followerProfileURL
        account.username = ""
        account.uid = follower
        account.name  = self.followerUsername
        
        return account
        
    }
    
    func getFollowedAccount() -> Account{
        
        let account = Account()
        account.profileURL = self.followedProfileURL
        account.username = ""
        account.uid = followed
        account.name = self.followedUsername
        
        return account
        
    }
}

extension Relationship : DatabaseRepresentation{
    
    var representation : [String : Any]{
        
        let rep : [String : Any] = [
            "follower":self.follower,
            "followerUsername":self.followerUsername,
            "followerProfileURL":self.followerProfileURL,
            "followed":self.followed,
            "followedUsername":self.followedUsername,
            "followedProfileURL":self.followedProfileURL,
            "isApproved":self.isApproved]
        
        return rep
    }
    
}

extension Relationship : DiffAware{
    
    static func compareContent(_ a: Relationship, _ b: Relationship) -> Bool {
        return a.id == b.id
       }
       

       
       var diffId: UUID? {
        let id = UUID(uuidString: self.id)
           return id
       }
       
       typealias DiffId = UUID?
    
    
}
