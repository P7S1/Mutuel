//
//  Message.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 10/28/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//
import AVFoundation
import Foundation
import FirebaseFirestore
import MessageKit
import FirebaseStorage
class Message : MessageType, Equatable, Comparable{
    
    var sender: SenderType
    
    var messageId: String
    
    var sentDate: Date
    
    var kind: MessageKind
    
    var photoURL : String?
    
    var messageKind : String?
    
    var profilePicURL : String?
    
    var placeHolderURL : String?
    
    var profileImage : UIImage = FollowersHelper().getUserProfilePicture()
    var content : String?
    
    init(sender: SenderType, messageId: String, sentDate: Date, kind: MessageKind) {
        self.sender = sender
        self.messageId = messageId
        self.sentDate = sentDate
        self.kind = kind
    }
    
    func printClass(){
       /*print("sender: \(String(describing: sender))\n")
        print("messageId: \(String(describing: messageId))\n")
        print("sentDate: \(String(describing: sentDate))\n")
        print("kind: \(String(describing: kind))\n")
        print("messageKind: \(String(describing: messageKind))\n")
        print("profilePicURL: \(String(describing: profilePicURL))\n")
        print("content: \(String(describing: content))\n") */
    }
    
    func convertFromDictionary(dictionary: NSDictionary){
        var id = User.shared.uid ?? ""
        var displayName = User.shared.name ?? ""
        if let x = dictionary.value(forKey: "senderUID"){
                   id = x as! String
               }
               if let x = dictionary.value(forKey: "sender"){
                   displayName  = x as! String
               }
               sender = Sender(id: id, displayName: displayName)
               if let x = dictionary.value(forKey: "sentDate"){
                    let timestamp = x as! Timestamp
                   sentDate  = timestamp.dateValue()
               }
               if let x = dictionary.value(forKey: "messageKind"){
                   messageKind  = x as? String
               }
        if messageKind == "photo"{
               if let x = dictionary.value(forKey: "profilePicURL"){
                   profilePicURL  = x as? String
                let image = FollowersHelper().getGroupProfilePicture()
                kind = .photo(ImageMediaItem(image: image))
               }
        } else if messageKind == "video"{
            
        }else{
               if let x = dictionary.value(forKey: "content"){
                   content  = x as? String
                   kind = MessageKind.text(content!)
        }
        }
        if let x = dictionary.value(forKey: "messageID"){
            messageId = x as? String ?? ""
               }
    }
    
    func convertFrom(dictionary: DocumentSnapshot){
        var id = ""
        var displayName = ""
        if let x = dictionary.get("uid"){
            id = x as! String
        }
        if let x = dictionary.get("sender"){
            displayName  = x as! String
        }
        sender = Sender(id: id, displayName: displayName)
        if let x = dictionary.get("sentDate"){
             let timestamp = x as! Timestamp
            sentDate  = timestamp.dateValue()
        }
        if let x = dictionary.get("messageKind"){
            messageKind  = x as? String
        }
        if messageKind == "photo"{
        if let x = dictionary.get("photoURL"){
            photoURL  = x as? String
        }
        let image = FollowersHelper().getGroupProfilePicture()
            kind = .photo(ImageMediaItem(image: image))
        }else if messageKind == "video"{
            if let x = dictionary.get("photoURL") as? String, let y = dictionary.get("placeHolderURL") as? String, let url = URL(string: x) {
                photoURL  = x
                placeHolderURL = y
                kind = .video(VideoMediaItem(videoURL: url))
            }
        }else{
        if let x = dictionary.get("content"){
            content  = x as? String
            kind = MessageKind.text(content ?? "")
        }
        }
        if let x = dictionary.get("messageID"){
            messageId = x as? String ?? ""
        }
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.messageId == rhs.messageId && rhs.sender.senderId == lhs.sender.senderId
    }
    
    static func < (lhs: Message, rhs: Message) -> Bool {
        return lhs.sentDate < rhs.sentDate
    }
    
    
    
    

}

private struct ImageMediaItem: MediaItem {

var url: URL?
var image: UIImage?
var placeholderImage: UIImage
var size: CGSize

init(image: UIImage) {
    self.image = image
    var width = 240
    var height = 240
    let aspectRatio = image.size.width/image.size.height
    width = width * Int(aspectRatio)
    height = height / Int(aspectRatio)
    self.size = CGSize(width: width, height: height)
    self.placeholderImage = image
    
}
}

private struct MockAudioItem: AudioItem {
    var url: URL
    var size: CGSize
    var duration: Float

    init(url: URL) {
        self.url = url
        self.size = CGSize(width: 160, height: 35)
        // compute duration
        let audioAsset = AVURLAsset(url: url)
        self.duration = Float(CMTimeGetSeconds(audioAsset.duration))
    }

}

private struct VideoMediaItem: MediaItem {
    var url: URL?
    
    var image: UIImage?
    
    var placeholderImage: UIImage
    
    var size: CGSize
    
    init(videoURL : URL) {
        self.placeholderImage = UIImage(named : "group")!
        self.url = videoURL
        self.size = CGSize(width: 240, height: 240)
    }

}

struct MockContactItem: ContactItem {
    var displayName: String
    var initials: String
    var phoneNumbers: [String]
    var emails: [String]
    
    init(name: String, initials: String, phoneNumbers: [String] = [], emails: [String] = []) {
        self.displayName = name
        self.initials = initials
        self.phoneNumbers = phoneNumbers
        self.emails = emails
    }
    
}
