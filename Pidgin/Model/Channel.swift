import Firebase
import DeepDiff
struct Channel : DiffAware {
    var diffId: UUID?
    
    static func compareContent(_ a: Channel, _ b: Channel) -> Bool {
        if let idA = a.lastSentMessageID, let readingA = a.reading{
            return a.id == b.id && idA == b.lastSentMessageID && readingA == b.reading
        }
        return false
    }
  var id: String?
  var name: String?
    var members : [String] = [String]()
    var messages : [Message] = [Message]()
    var lastSentMessage : String?
    var lastMesssageText : String?
    var lastMessageDate : Date?
    var lastSentUser : String?
    var lastSentMessageID : String?
    var metaData : NSMutableDictionary?
    var profilePics : NSMutableDictionary?
    var lastOpened : NSMutableDictionary?
    var reading : NSMutableDictionary?
    var tokens : [String] = [String]()
    var groupChat : Bool?
    
  init(name: String) {
    id = nil
    self.name = name
  }
  
  init?(document: DocumentSnapshot) {
    print("attempting to init channel")
    let data = document.data()
    
    if let name = data?["name"] as? String {
      self.name = name
    }
    
    if let members = data?["members"] as? [String]{
        self.members = members
    }
    
    if let metaData = data?["metaData"] as? NSMutableDictionary{
        self.metaData = metaData
    }
    
    if let profilePics = data?["profilePicURLs"] as? NSMutableDictionary{
        self.profilePics = profilePics
    }
    
    if let lastOpened = data?["lastOpened"] as? NSMutableDictionary{
        self.lastOpened = lastOpened
    }
    
    if let reading = data?["reading"] as? NSMutableDictionary{
        self.reading = reading
    }
    
    if let lastMesssageText = data?["lastSentMessage"] as? String{
        self.lastMesssageText = lastMesssageText
    }
    
    if let lastSentMessageID = data?["lastSentMessageID"] as? String{
        self.lastSentMessageID = lastSentMessageID
    }
    
    if let date = data?["lastSentDate"] as? Timestamp{
        self.lastMessageDate = date.dateValue()
    }
    
    if let lastSentUser = data?["lastSentUser"] as? String{
        self.lastSentUser = lastSentUser
    }
    
    if let tokens = data?["fcmToken"] as? [String]{
        self.tokens = tokens
    }
    
    if let groupChat = data?["groupChat"] as? Bool{
        self.groupChat = groupChat
    }
    
    id = document.documentID
    
    print("channel created successfully")
  }
    
    func getSenderID() -> String? {
        print("getting sender id")
    for member in members{
        if member != User.shared.uid{
            return member
        }
    }
        return nil
    }
  
}

extension Channel: DatabaseRepresentation {
  
  var representation: [String : Any] {
    var rep = ["name": name]
    
    if let id = id {
      rep["id"] = id
    }
    return rep as [String : Any]
  }
  
}

extension Channel: Comparable {
  
  static func == (lhs: Channel, rhs: Channel) -> Bool {
    return lhs.id == rhs.id
  }
  
  static func < (lhs: Channel, rhs: Channel) -> Bool {
    if lhs.lastMessageDate != nil, rhs.lastMessageDate != nil{
        print("comparison not nil")
        return lhs.lastMessageDate! > rhs.lastMessageDate!
    }
    return lhs.lastMessageDate ?? Date() > rhs.lastMessageDate ?? Date()
  }

}



/*import Foundation
import FirebaseFirestore
struct Channel{
    var name : String?
    var channelID : String?
    var messages : [Message] = [Message]()
    
    mutating func handleSnapshot(snapshot : QuerySnapshot){
        for document in snapshot.documents{
            name = document.get("name") as? String
        }
    }
}
*/
