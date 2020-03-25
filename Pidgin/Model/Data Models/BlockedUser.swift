//
//  BlockedUser.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/22/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import Foundation
import FirebaseFirestore
class BlockedUser {
    
    var username : String
    var id : String
    var creationDate : Date
    
    lazy var docRef : DocumentReference = {
        let docRef = db.collection("users").document(User.shared.uid!).collection("blocked").document(id)
        
        return docRef
    }()
    
    init(document : DocumentSnapshot) {
        let data = document.data()
        username = data?["username"] as? String ?? ""
        id = document.documentID
        let timestmap = data?["creationDate"] as? Timestamp ?? Timestamp()
        creationDate = timestmap.dateValue()
    }
    
    init(user : Account) {
        self.username = user.username ?? ""
        self.id = user.uid ?? ""
        self.creationDate = Date()
    }
    
     func blockUser(completion: @escaping (Bool) -> Void){
        self.docRef.setData(self.representation, merge: true) { (error) in
            if error == nil{
                completion(true)
            }else{
                print("there was an error: \(error!.localizedDescription)")
                completion(false)
            }
        }
        
        
        
    }
    
    func unblockUser(completion: @escaping (Bool) -> Void){
        self.docRef.delete { (error) in
            if error == nil{
              completion(true)
            }else{
                print("there was an error :\(error!.localizedDescription)")
              completion(false)
            }
        }
    }
    
}

extension BlockedUser : DatabaseRepresentation {
    var representation: [String : Any] {
        return ["username" : self.username,
                "id" : self.id,
                "creationDate" : Timestamp(date: self.creationDate)]
    }
}
