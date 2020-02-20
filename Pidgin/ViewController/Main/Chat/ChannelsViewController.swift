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
import DeepDiff
var channels = [Channel]()
var channelListener: ListenerRegistration?
class ChannelsViewController: HomeViewController, UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
  
  private var channelReference: CollectionReference {
    return db.collection("channels")
  }
    
    var lastDocument : DocumentSnapshot?
    
    var query : Query!
    
    var loadedAllPosts = false
    
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    configureNavItem(name: "Chats")
    tableView.delegate = self
    tableView.dataSource = self
    
    if let userID = User.shared.uid{
        
    query = channelReference.whereField("members", arrayContains: userID).limit(to: 15).order(by: "lastSentDate", descending: true)
    
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
    }
    
 
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  // MARK: - Actions
  
  

  
  // MARK: - Helpers
  
  private func addChannelToTable(_ channel: Channel) {
    print("add channel to table")
    guard !channels.contains(channel) else {
      return
    }
    
    let old = channels
        var newItems = channels
    newItems.append(channel)
        newItems.sort()
   
        let changes = diff(old: old, new: newItems)
        tableView.reload(changes: changes, section: 0, updateData: {
          channels = newItems
        })
  

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
    let old = channels
        var newItems = channels
        newItems[index] = channel
        newItems.sort()
            let changes = diff(old: old, new: newItems)
            tableView.reload(changes: changes, section: 0, updateData: {
              channels = newItems
            })
        
     NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadData"), object: nil)
  }
    
  private func removeChannelFromTable(_ channel: Channel) {
    print("remove channel")
    guard let index = channels.firstIndex(of: channel) else {
      return
    }
    let old = channels
        var newItems = channels
    newItems.remove(at: index)
        newItems.sort()

        let changes = diff(old: old, new: newItems)
        tableView.reload(changes: changes, section: 0, updateData: {
          channels = newItems
        })
    
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
    
    func getMorePosts(){
        if let lastdoc = self.lastDocument{
            query = query.start(afterDocument: lastdoc)
        }
        query.getDocuments { (snapshot, error) in
            if error == nil{
                if snapshot!.count < 15{
                    self.loadedAllPosts = true
                }
                for document in snapshot!.documents{
                    self.lastDocument = document
                    if let channel = Channel(document: document){
                    self.addChannelToTable(channel)
                    }
                }
            }
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
      return 65
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        if self.loadedAllPosts{
        footer.activityIndicator(show: false)
        }else{
        footer.activityIndicator(show: true)
        }
        return footer
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == channels.count && !self.loadedAllPosts{
            getMorePosts()
        }
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
                            cell.message.text = "Read \(lastOpen.dateValue().getElapsedInterval())"
                        }else if channels[indexPath.row].reading?.value(forKey: key) as? Bool == true {
                            cell.message.text = "Read \(Date().getElapsedInterval())"
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
        cell.timeStamp.text = date.getElapsedInterval()
    }
    
    cell.readIndicator.isHidden = true
        
    if channels[indexPath.row].groupChat == nil{
        for i in channels[indexPath.row].members{
            if i != User.shared.uid{
                channels[indexPath.row].name = channels[indexPath.row].metaData?.value(forKey: i) as? String ?? ""
                cell.displayName.text = channels[indexPath.row].metaData?.value(forKey: i) as? String ?? ""
                
                if let url = channels[indexPath.row].profilePics?.value(forKey: i) as? String{
                    DispatchQueue.main.async {
                        cell.profilePic.kf.setImage(with: URL(string: url), placeholder: FollowersHelper().getUserProfilePicture())
                    }
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
            DispatchQueue.main.async {
                cell.profilePic.kf.setImage(with: URL(string: url), placeholder: FollowersHelper().getUserProfilePicture())
            }
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

extension ChannelsViewController{
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if scrollView.panGestureRecognizer.translation(in: scrollView).y < 0{
            changeTabBar(hidden: true, animated: true)
        }
        else{
            changeTabBar(hidden: false, animated: true)
        }
    }

    func changeTabBar(hidden:Bool, animated: Bool){
        guard let tabBar = self.tabBarController?.tabBar else { return; }
        if tabBar.isHidden == hidden{ return }
        let frame = tabBar.frame
        let offset = hidden ? frame.size.height : -frame.size.height
        let duration:TimeInterval = (animated ? 0.2 : 0.0)
        tabBar.isHidden = false

        UIView.animate(withDuration: duration, animations: {
            tabBar.frame = frame.offsetBy(dx: 0, dy: offset)
        }, completion: { (true) in
            tabBar.isHidden = hidden
        })
    }
}
