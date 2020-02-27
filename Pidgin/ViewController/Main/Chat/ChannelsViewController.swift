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
protocol ChannelDelegate {
    func updateChannel(channel : Channel)
}
class ChannelsViewController: HomeViewController, UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
  
  private var channelReference: CollectionReference {
    return db.collection("channels")
  }
    
    var channels = [Channel]()
    var channelListener: ListenerRegistration?
    
    var lastDocument : DocumentSnapshot?
    
    var query : Query!
    
    var loadedAllPosts = false
    
    var channelDelegate : ChannelDelegate?
    
    
    
    deinit {
        print("deinit")
        channelListener?.remove()
    }
    
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    configureNavItem(name: "Chats")
    tableView.delegate = self
    tableView.dataSource = self
    
    if let userID = User.shared.uid{

    query = channelReference.whereField("members", arrayContains: userID).limit(to: 25).order(by: "lastSentDate", descending: true)
        
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

  // MARK: - Actions
  
  

  
  // MARK: - Helpers
  
  private func addChannelToTable(_ channel: Channel) {
    
    let old = channels
    var newItems = channels
    
    if channels.contains(channel) {
        let index = channels.firstIndex(of: channel)
        channels.remove(at: index!)
        channels.insert(channel, at: index!)
    }else{
        newItems.append(channel)
    }
        newItems.sort()
   
        let changes = diff(old: old, new: newItems)
        tableView.reload(changes: changes, section: 0, updateData: {
          channels = newItems
        })
  

  }
    
  
    private func updateChannelInTable(ch: Channel) {
        let channel = ch
        guard let index = channels.firstIndex(of: channel) else {
      return
    }
        
    let old = channels
        var newItems = channels
        newItems[index] = channel
        newItems.sort()
            let changes = diff(old: old, new: newItems)
            tableView.reload(changes: changes, section: 0, updateData: {
              channels = newItems
            })
        
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
    let channel = Channel(document: change.document)
    
    lastDocument = change.document
    
    self.channelDelegate?.updateChannel(channel: channel)
    
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
                if snapshot!.count < 25{
                    self.loadedAllPosts = true
                }
                for document in snapshot!.documents{
                    self.lastDocument = document
                     let channel = Channel(document: document)
                    self.addChannelToTable(channel)
                    
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
    
    let channel = channels[indexPath.row]
    var id = ""
    if channel.groupChat{
        id = channel.id
        cell.displayName.text = channel.name
    }else{
        id = channel.getSenderID()
        cell.displayName.text = channel.metaData.value(forKey: id) as? String ?? ""
    }
    
    
    let photoURL = channel.profilePics.value(forKey: id) as? String ?? ""
    cell.profilePic.kf.setImage(with: URL(string: photoURL), placeholder: FollowersHelper().getUserProfilePicture())
    
    cell.message.text = channel.lastMesssageText
    
    cell.timeStamp.text = channel.lastMessageDate.getElapsedInterval()
    
    let timestamp = channel.lastOpened.value(forKey: User.shared.uid ?? "") as? Timestamp ?? Timestamp()
    let lastRead = timestamp.dateValue()
    
    cell.displayName.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
    cell.displayName.textColor = .label
    if lastRead > channel.lastMessageDate || channel.lastSentUser == User.shared.uid{
        cell.readIndicator.isHidden = true
        cell.timeStamp.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        cell.message.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        cell.timeStamp.textColor = .secondaryLabel
        cell.message.textColor = .secondaryLabel
    }else{
        cell.readIndicator.isHidden = false
        cell.timeStamp.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        cell.message.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        cell.timeStamp.textColor = .label
        cell.message.textColor = .label

    }
    
    cell.profilePic.layer.cornerRadius = cell.profilePic.frame.height/2
    cell.profilePic.clipsToBounds = true
    
    


    
    return cell
  }

   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let channel = channels[indexPath.row]
    let vc = ChatViewController()
    
    vc.channel = channel
    channelDelegate = vc
    navigationController?.pushViewController(vc, animated: true)

  }
  
}

