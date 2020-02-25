import Firebase
import DeepDiff
struct Channel : DiffAware {
    var diffId: UUID?
    
    static func compareContent(_ a: Channel, _ b: Channel) -> Bool {
        if let lastOpenedA = a.lastOpened.value(forKey: User.shared.uid ?? "") as? Timestamp,
            let lastOpenedB = b.lastOpened.value(forKey: User.shared.uid ?? "") as? Timestamp{
         return a.id == b.id && a.lastSentMessageID == b.lastSentMessageID && lastOpenedA == lastOpenedB
        }else{
        return a.id == b.id && a.lastSentMessageID == b.lastSentMessageID
        }

    }
    
  var id: String
  var name: String
    var members : [String] = [String]()
    var messages : [Message] = [Message]()
    var lastMesssageText = ""
    var lastMessageDate = Date()
    var lastSentUser = ""
    var lastSentMessageID = ""
    var metaData = NSMutableDictionary()
    var profilePics = NSMutableDictionary()
    var lastOpened = NSMutableDictionary()
    var reading = NSMutableDictionary()
    var groupChat = false
    
    
    init(id: String, name : String) {
        self.id = id
        self.name = name
    }
    
  
  init(document: DocumentSnapshot) {
    let data = document.data()
    
      self.name = data?["name"] as? String ?? ""
    
      self.members = data?["members"] as? [String] ?? [String]()
    
        self.metaData = data?["metaData"] as? NSMutableDictionary ?? NSMutableDictionary()
    

        self.profilePics = data?["profilePicURLs"] as? NSMutableDictionary ?? NSMutableDictionary()

        self.lastOpened = data?["lastOpened"] as? NSMutableDictionary ?? NSMutableDictionary()
    
        self.reading = data?["reading"] as? NSMutableDictionary ?? NSMutableDictionary()
    
        self.lastMesssageText = data?["lastSentMessage"] as? String ?? ""
    
        self.lastSentMessageID = data?["lastSentMessageID"] as? String ?? ""
    
    
    if let date = data?["lastSentDate"] as? Timestamp{
        self.lastMessageDate = date.dateValue()
    }else{
        self.lastMessageDate = Date()
    }
    self.lastSentUser = data?["lastSentUser"] as? String ?? ""
    
    self.groupChat = data?["groupChat"] as? Bool ?? false
    
    
    id = document.documentID
  
  
}
    
    func getSenderID() -> String {
    for member in members{
        if member != User.shared.uid{
            return member
        }
    }
        return ""
    }

    
    func isUserReading(uid : String) -> Bool{
        if let reading = reading.value(forKey: uid) as? Bool{
            return reading
        }else{
            return false
        }
    }
    
    func getLastOpened(uid : String) -> Date?{
        if let lastOpened = lastOpened.value(forKey: uid) as? Timestamp{
            return lastOpened.dateValue()
        }else{
            return nil
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
}

extension Channel: Comparable {
  
  static func == (lhs: Channel, rhs: Channel) -> Bool {
    return lhs.id == rhs.id
  }
  
  static func < (lhs: Channel, rhs: Channel) -> Bool {
        return lhs.lastMessageDate > rhs.lastMessageDate
  }

}
