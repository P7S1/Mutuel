//
//  MessagesViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 10/8/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//
import UIKit
import FirebaseAuth
import FirebaseFirestore
import GiphyUISDK
import GiphyCoreSDK
var channels = [Channel]()
var channelListener: ListenerRegistration?
class ChannelsViewController: HomeViewController, UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
  
  private var channelReference: CollectionReference {
    return db.collection("channels")
  }
    
    var lastDocument : DocumentSnapshot?
    
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    configureNavItem(name: "Chats")
    tableView.delegate = self
    tableView.dataSource = self
    tableView.prefetchDataSource = self
    
    if let userID = User.shared.uid{
        
    let query = channelReference.whereField("members", arrayContains: userID).limit(to: 25).order(by: "lastSentDate", descending: true)
    
    channelListener = query.addSnapshotListener { querySnapshot, error in
      guard let snapshot = querySnapshot else {
        print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
        return
      }
      snapshot.documentChanges.forEach { change in
        self.handleDocumentChange(change)
      }
    
    }
        
    }else{
        print("getting user id failed")
    }
    
  }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if Auth.auth().currentUser != nil {
            
            print("user is signed in")
        } else {
            print("user is not signed in")
            returnToLoginScreen()
        }
    }
    
 
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    tableView.reloadData()
  }
  
  // MARK: - Actions
  
  

  
  // MARK: - Helpers
  
  private func addChannelToTable(_ channel: Channel) {
    print("add channel to table")
    guard !channels.contains(channel) else {
      return
    }
    
    channels.append(channel)
    channels.sort()
    
    guard let index = channels.firstIndex(of: channel) else {
      return
    }
    tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)

  }
  
    private func updateChannelInTable(ch: Channel) {
        let channel = ch
    print("update channel")
        guard let index = channels.firstIndex(of: channel) else {
      return
    }
        if (channels[index].lastSentMessageID != channel.lastSentMessageID) && (channel.lastSentUser != User.shared.uid){
            let userInfo = NSMutableDictionary()
            if channel.groupChat == nil{
                userInfo.setValue(channel.metaData?.value(forKey: channel.getSenderID() ?? ""), forKey: "title")
                userInfo.setValue("New Message", forKey: "message")
                userInfo.setValue(channel.profilePics?.value(forKey: channel.getSenderID() ?? ""), forKey: "photoURL")
            }else{
                userInfo.setValue(channel.name, forKey: "title")
                userInfo.setValue("from \(channel.metaData?.value(forKey: channel.getSenderID() ?? "") ?? "")", forKey: "message")
                userInfo.setValue(channel.profilePics?.value(forKey: channel.id ?? ""), forKey: "photoURL")
            }
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "presentNotification"), object: nil, userInfo: userInfo as? [AnyHashable : Any])
            print("sending notificaiton")
        }
        
    channels[index] = channel
    channels.sort()
        tableView.beginUpdates()
        tableView.reloadData()
        tableView.endUpdates()
     NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadData"), object: nil)
  }
    
  private func removeChannelFromTable(_ channel: Channel) {
    print("remove channel")
    guard let index = channels.firstIndex(of: channel) else {
      return
    }
    channels.remove(at: index)
    tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
  }
  
  private func handleDocumentChange(_ change: DocumentChange) {
    print("handle doc change channel")
    guard let channel = Channel(document: change.document) else {
      return
    }
    
    lastDocument = change.document
    
    switch change.type {
    case .added:
      addChannelToTable(channel)
      
    case .modified:
        updateChannelInTable(ch: channel)
      
    case .removed:
      removeChannelFromTable(channel)
    }
  }
  
}

// MARK: - TableViewDelegate

extension ChannelsViewController {
  
   func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return channels.count
  }
 /*   func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let returnedView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)) //set these values as necessary
        returnedView.backgroundColor = UIColor.secondarySystemBackground

        return returnedView
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 32
    } */
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      return 75
    }
  
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelCell", for: indexPath) as! ChannelTableViewCell
    
    if let lastMsg = channels[indexPath.row].lastMesssageText{
        if let lastSender = channels[indexPath.row].lastSentUser{
            
            if channels[indexPath.row].groupChat == nil{
                if lastSender != User.shared.uid ?? ""{
                    cell.message.text = "New message"
                }else{
                    cell.message.text = "Delivered"
                    if let key = channels[indexPath.row].getSenderID(),
                        let lastOpen = channels[indexPath.row].lastOpened?.value(forKey: key) as? Timestamp,
                        let lastSent = channels[indexPath.row].lastMessageDate{
                        if lastOpen.dateValue() > lastSent{
                            cell.message.text = "Read \(FollowersHelper().dayDifference(from: lastOpen.dateValue().timeIntervalSince1970).lowercased())"
                        }else if channels[indexPath.row].reading?.value(forKey: key) as? Bool == true {
                            cell.message.text = "Read \(FollowersHelper().dayDifference(from: Date().timeIntervalSince1970).lowercased())"
                        }
                    }
                }
            }else{
                let sender = channels[indexPath.row].metaData?.value(forKey: lastSender) as? String ?? ""
                if sender == User.shared.uid{
                    cell.message.text = "Delivered"
                }else{
                    if lastSender == User.shared.uid{
                cell.message.text = "Delivered"
                    }else{
                cell.message.text = "\(sender): New message"
                    }
                }
                
            }
        
            
            
            
        }else{
        cell.message.text = lastMsg
        }
    }
    else{
        cell.message.text = ""
    }
    
    if let date = channels[indexPath.row].lastMessageDate{
        print(date)
        cell.timeStamp.text = FollowersHelper().dayDifference(from: date.timeIntervalSince1970)
    }
    
    cell.readIndicator.isHidden = true
        
    if channels[indexPath.row].groupChat == nil{
        for i in channels[indexPath.row].members{
            if i != User.shared.uid{
                channels[indexPath.row].name = channels[indexPath.row].metaData?.value(forKey: i) as? String ?? ""
                cell.displayName.text = channels[indexPath.row].metaData?.value(forKey: i) as? String ?? ""
                
                if let url = channels[indexPath.row].profilePics?.value(forKey: i) as? String{
                    cell.profilePic.kf.setImage(with: URL(string: url), placeholder: FollowersHelper().getUserProfilePicture())
                }else{
                    cell.profilePic.image = FollowersHelper().getUserProfilePicture()
                }
                cell.profilePic.clipsToBounds = true
                cell.profilePic.layer.cornerRadius = cell.profilePic.bounds.height/2
            }
        }
    }else{
        cell.displayName.text = channels[indexPath.row].name
        if let id = channels[indexPath.row].id,
            let url = channels[indexPath.row].profilePics?.value(forKey: id) as? String{
            cell.profilePic.kf.setImage(with: URL(string: url), placeholder: FollowersHelper().getUserProfilePicture())
            cell.profilePic.clipsToBounds = true
            cell.profilePic.layer.cornerRadius = cell.profilePic.bounds.height/2
        }else{
            cell.profilePic.image = FollowersHelper().getGroupProfilePicture()
        }
    }
    cell.displayName.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
    cell.message.textColor = .secondaryLabel
    cell.message.font = UIFont.systemFont(ofSize: 15, weight: .regular)
    cell.timeStamp.textColor = .secondaryLabel
    cell.timeStamp.font = UIFont.systemFont(ofSize: 15, weight: .regular)
    
    if let lastMsgDate = channels[indexPath.row].lastMessageDate,
        let lastOpenDate = channels[indexPath.row].lastOpened?.value(forKey: User.shared.uid ?? "") as? Timestamp{
        if lastMsgDate > lastOpenDate.dateValue(){
            if channels[indexPath.row].lastSentUser != User.shared.uid{
        cell.readIndicator.isHidden = false
        cell.displayName.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        cell.message.textColor = .label
        cell.message.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        cell.timeStamp.textColor = .label
        cell.timeStamp.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
            }    }
    }
    

    
    return cell
  }

   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let channel = channels[indexPath.row]
    let vc = ChatViewController()
    
    vc.channel = channel
    navigationController?.pushViewController(vc, animated: true)

  }
  
}

extension ChannelsViewController : UITableViewDataSourcePrefetching{
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        print("prefetch rows")

}
}
