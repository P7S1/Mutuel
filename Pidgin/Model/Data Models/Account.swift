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
import DeepDiff
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
    var followingCount : Int?
    var isPrivate = false
    var followRequestsCount = 0
    
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
        self.isPrivate = dictionary.value(forKey: "isPrivate") as? Bool ?? false
        self.followRequestsCount = dictionary.value(forKey: "followRequestsCount") as? Int ?? 0
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
        if let c = dictionary.get("birthday") as? Timestamp{
            birthday = c.dateValue()
        }
        if let c = dictionary.get("following"){
            following = c as? [String] ?? [String]()
        }
        if let c = dictionary.get("followersCount"){
            followersCount = c as? Int
        }
        if let c = dictionary.get("followingCount"){
            followingCount = c as? Int
        }
        if let c = dictionary.get("fcmToken"){
            tokens = c as? [String] ?? [String]()
        }
        self.isPrivate = dictionary.get("isPrivate") as? Bool ?? false
        self.followRequestsCount = dictionary.get("followRequestsCount") as? Int ?? 0
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

extension Account : DiffAware{
    var diffId: UUID? {
        let id = UUID(uuidString: self.uid ?? "")
        return id
    }
    
    typealias DiffId = UUID?
    

    static func compareContent(_ a: Account, _ b: Account) -> Bool {
        return (a.uid ?? "" == b.uid ?? "")
    }
    
}

class User : Account{
    static var shared = User()
    
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
        username = nil
        phoneNumber = nil
        email = nil
        uid = nil
        name = nil
        birthday = nil
    }
    
    func invalidateToken(completion: @escaping (Bool) -> Void){
        let user = User.shared
        userListener?.remove()
        ProgressHUD.show()
        if  let userID = user.uid,
            let deviceID = UIDevice.current.identifierForVendor?.uuidString{
            ref.child("devices/\(userID)/\(deviceID)").removeValue() { (error, ref) in
                if error == nil{
                    completion(true)
                }else{
                    completion(false)
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

extension User : DatabaseRepresentation{
    
    var representation : [String : Any]{
        let rep : [String : Any] = [
            "username":username as Any,
            "email":email as Any,
            "profilePicURL":profileURL as Any,
            "birthday":Timestamp(date: birthday ?? Date()),
            "name": name as Any,
            "isPrivate": self.isPrivate]
        return rep
    }
    
}
