//
//  Account.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 10/23/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import Foundation
import Firebase
import MessageKit
class Account: Comparable{
    static func < (lhs: Account, rhs: Account) -> Bool {
        if let id1 = lhs.uid, let id2 = rhs.uid{
        return id1 < id2
        }
        return false
    }
    
    static func == (lhs: Account, rhs: Account) -> Bool {
        if let id1 = lhs.uid, let id2 = rhs.uid{
        return id1 == id2
        }
        return false
    }
    
    var username : String?
    var phoneNumber : Int?
    var email : String?
    var profileURL : String?
    var uid : String?
    var name : String?
    var birthday : Date?
    var following : [String] = [String]()
    var tokens : [String] = [String]()
    var followersCount : Int?
    
    
    func convertFrom(dictionary: NSDictionary){
        if let c = dictionary.value(forKey: "username"){
            username = c as? String
        }
        if let c = dictionary.value(forKey: "phoneNumber"){
            phoneNumber = c as? Int
        }
        if let c = dictionary.value(forKey: "email"){
            email = c as? String
        }
        if let c = dictionary.value(forKey: "profilePicURL"){
            profileURL = c as? String
        }
        if let c = dictionary.value(forKey: "uid"){
            uid = c as? String
        }
        if let c = dictionary.value(forKey: "name"){
            name = c as? String
        }
        if let c = dictionary.value(forKey: "birthday"){
            birthday = c as? Date
        }
    }
    
    func convertFromDocument(dictionary: DocumentSnapshot){
        if let c = dictionary.get("username"){
            username = c as? String
        }
        if let c = dictionary.get("phoneNumber"){
            phoneNumber = c as? Int
        }
        if let c = dictionary.get("email"){
            email = c as? String
        }
        if let c = dictionary.get("profilePicURL"){
            profileURL = c as? String
        }
        if let c = dictionary.get("name"){
            name = c as? String
        }
        if let c = dictionary.get("birthday"){
            birthday = c as? Date
        }
        if let c = dictionary.get("following"){
            following = c as? [String] ?? [String]()
        }
        if let c = dictionary.get("followerCount"){
            followersCount = c as? Int
        }
        if let c = dictionary.get("fcmToken"){
            tokens = c as? [String] ?? [String]()
        }
        self.uid = dictionary.documentID
    }
    
    func printClass(){
       print("username: \(String(describing: username))\n")
        print("phoneNumber: \(String(describing: phoneNumber))\n")
        print("email: \(String(describing: email))\n")
        print("profileURL: \(String(describing: profileURL))\n")
        print("uid: \(String(describing: uid))\n")
        print("name: \(String(describing: name))\n")
        print("birthday: \(String(describing: birthday))\n")
    }
}

class User : Account{
    static var shared = User()
    var password : String?
    
    func setUser(Email : String, UID : String, Name : String, Birthday : String, Username : String){
        invalidateUser()
        email = Email
        uid = UID
        name = Name
        username = Username
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        birthday = formatter.date(from: Birthday)
    }
    
    func invalidateUser(){
        userListener?.remove()
        channelListener?.remove()
        channels.removeAll()
        username = nil
        phoneNumber = nil
        email = nil
        uid = nil
        name = nil
        birthday = nil
    }
    
    func invalidateToken(){
        userListener?.remove()
        channelListener?.remove()
        channels.removeAll()
        if let token = Messaging.messaging().fcmToken{
            let query = db.collection("channels").whereField("fcmToken", arrayContains: token).whereField("active", isEqualTo: true)
            query.getDocuments { (snapshot, error) in
                if error == nil{
                    for document in snapshot!.documents{
                    let docRef = db.collection("channels").document(document.documentID)
                    
                    docRef.updateData([
                        "fcmToken": FieldValue.arrayRemove([token]),
                    ]) { err in
                        if let err = err {
                            print("Error updating document: \(err)")

                        } else {
                            print("Document successfully updated")
                            
                        }
                    }
                    }
                }else{
                    print("therew as an error: \(error!)")
                }
            }
            let docRef = db.collection("users").document(User.shared.uid ?? "")
            docRef.updateData([
                "fcmToken": FieldValue.arrayRemove([token]),
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")

                } else {
                    print("Document successfully updated")
        
                }
            }
            
        }
        
    }
    
    func getFormattedDate() -> String{
        var output = ""
        if let bday = birthday{
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
            output = formatter.string(from: bday)
        }else{
        print("getting formatted birthday failure")
        }
        return output
    }
}
