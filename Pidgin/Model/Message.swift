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
import DeepDiff
class Message : MessageType, Equatable, Comparable, DiffAware{
    
    var sender: SenderType
    
    var messageId: String
    
    var sentDate: Date
    
    var kind: MessageKind
    
    var photoURL : String?
    
    var messageKind = "text"
    
    var isDelivered = false
    
    var profilePicURL : String?
    
    var placeHolderURL : String?
    
    var profileImage : UIImage = FollowersHelper().getUserProfilePicture()
    var content : String?
    
    var diffId: UUID?

    static func compareContent(_ a: Message, _ b: Message) -> Bool {
        return a.messageId == b.messageId && a.isDelivered == b.isDelivered
    }
    
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
    
    func convertFrom(dictionary: DocumentSnapshot){
        var id = ""
        var displayName = ""
        if let x = dictionary.get("uid") as? String{
            id = x
        }
        if let x = dictionary.get("sender")  as? String{
            displayName  = x
        }
        sender = Sender(id: id, displayName: displayName)
        if let x = dictionary.get("sentDate") as?  Timestamp{
            sentDate  = x.dateValue()
        }
        if let x = dictionary.get("messageKind") as? String{
            messageKind  = x
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
        if let x = dictionary.get("content") as? String{
            content  = x
            if x.containsOnlyEmoji && x.count < 4{
                kind = MessageKind.emoji(x)
            }else{
                kind = MessageKind.text(self.content ?? "")
            }
        }
        }
        if let x = dictionary.get("messageID"){
            messageId = x as? String ?? ""
        }
        if let x = dictionary.get("delivered") as? Bool{
            self.isDelivered = x
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
