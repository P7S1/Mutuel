//
//  ChatViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 10/27/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import MessageKit
import FirebaseFirestore
import InputBarAccessoryView
import AVFoundation
import FirebaseAuth
import FirebaseStorage
import Photos
import Lightbox
import GiphyUISDK
import GiphyCoreSDK
class ChatViewController: MessagesViewController {
    
    var name = ""
    
    var url = ""
    
    var chatListener : ListenerRegistration?
    
    var didViewAppear = false
    
    var editingIndex = 0

    var channel: Channel?
    
    let refreshControl = UIRefreshControl()
    
    var lastDocument : DocumentSnapshot?
    
    let sentSound: SystemSoundID = 1004
    
    let recievedSound: SystemSoundID = 1003
    
    var listenerHasRan = false
    
    static var lastMessage : NSMutableDictionary = NSMutableDictionary()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    updateLastOpened()
    refreshControl.beginRefreshing()
     GiphyUISDK.configure(apiKey: "jqEwvwCYxQjIehwIZpHnLKns5NMG0rd8")
    NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name:NSNotification.Name(rawValue: "reloadData"), object: nil)
    NotificationCenter.default.addObserver(self,
    selector: #selector(applicationWillEnterForeground),
    name: UIApplication.willEnterForegroundNotification,
    object: nil)
    
    NotificationCenter.default.addObserver(self,
    selector: #selector(applicationWillEnterBackground),
    name: UIApplication.willResignActiveNotification,
    object: nil)
    scrollsToBottomOnKeyboardBeginsEditing = true
    
    messageInputBar.delegate = self
    messagesCollectionView.delegate = self
    messagesCollectionView.messageCellDelegate = self
    messagesCollectionView.messagesDataSource = self
    messagesCollectionView.messagesLayoutDelegate = self
    messagesCollectionView.messagesDisplayDelegate = self
    self.messageInputBar.inputTextView.delegate = self

    messagesCollectionView.addSubview(refreshControl)
    refreshControl.addTarget(self, action: #selector(loadMoreMessages), for: .valueChanged)
    
    messageInputBar.sendButton.setSize(CGSize(width: 40, height: 40), animated: false)
    messageInputBar.setRightStackViewWidthConstant(to: 36, animated: false)
    messageInputBar.sendButton.tintColor = .systemPink
    messageInputBar.sendButton.image = UIImage(systemName: "paperplane.fill")
    messageInputBar.sendButton.title = nil
    messageInputBar.sendButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
    messageInputBar.middleContentViewPadding.right = -38
    createCameraButton()
    
    let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout
    layout?.sectionInset = UIEdgeInsets(top: 1, left: 8, bottom: 1, right: 8)
    
    layout?.setMessageOutgoingAvatarSize(.zero)
    if channel?.groupChat == nil{
        layout?.setMessageIncomingAvatarSize(.zero)
        layout?.setMessageIncomingMessageTopLabelAlignment(LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)))
    }
    layout?.setMessageOutgoingMessageBottomLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)))
    
    if channel?.groupChat ?? false{
    name = channel?.name ?? "Unknown"
    url = channel?.profilePics?.value(forKey: channel?.id ?? "") as? String ?? ""
    }else{
        for member in channel?.members ?? [String](){
            if member != User.shared.uid{
                // the UIButton is simply there to capture touch up event on the entire bar button view.
                name = channel?.metaData?.value(forKey: member) as? String ?? ""
                url = channel?.profilePics?.value(forKey: member) as? String ?? ""
            }
        }
    }

    navigationItem.title = name
    
    navigationItem.largeTitleDisplayMode = .never
    
    //maintainPositionOnKeyboardFrameChanged = true
    //messageInputBar.sendButton.setTitleColor(.primary, for: .normal)
    if #available(iOS 13.0, *) {
        configureMessageForDarkMode()
    }
    
        setSetttingsButton()
    
  }
    
    @objc func reloadData(){
        if let chan = channel, let index = channels.firstIndex(of: chan){
            channel?.lastOpened = channels[index].lastOpened
            channel?.lastMessageDate = channels[index].lastMessageDate
            channel?.reading = channels[index].reading
            
        }
        if self.didViewAppear{
        messagesCollectionView.reloadData()
        }else{
            messagesCollectionView.reloadDataAndKeepOffset()
        }
    }
    
    @objc func applicationWillEnterForeground(){
        updateLastOpened()
    }
    
    @objc func applicationWillEnterBackground(){
        removeLastOpened()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        didViewAppear = true
        if Auth.auth().currentUser != nil {
            print("user is signed in")
        } else {
            print("user is not signed in")
            returnToLoginScreen()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        writeLastOpened()
        UIView.animate(withDuration: 0.2) {
            self.tabBarController?.tabBar.isHidden = true
        }
        getMessageArray()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeLastOpened()
        UIView.animate(withDuration: 0.2) {
            self.tabBarController?.tabBar.isHidden = false
        }
        chatListener?.remove()
    }
    
    func removeLastOpened(){
       print("writing last opened...")
        if let id = channel?.id, let uid = User.shared.uid{
        let docRef = db.collection("channels").document(id)
             docRef.updateData(["lastOpened.\(uid)" : Timestamp(date: Date()),
                                "reading.\(uid)" : false])
        }
    }
    
    func updateLastOpened(){
        writeLastOpened()
    }
    func writeLastOpened(){
        print("writing last opened...")
        if let id = channel?.id, let uid = User.shared.uid{
       let docRef = db.collection("channels").document(id)
            docRef.updateData(["lastOpened.\(uid)" : Timestamp(date: Date()),
                               "reading.\(uid)" : true])
        }
    }
    
    func createCameraButton(){
        let cameraItem = InputBarButtonItem(type: .system) // 1
        cameraItem.tintColor = .secondaryLabel
        cameraItem.image = UIImage.init(systemName: "camera.fill")
        cameraItem.addTarget(
          self,
          action: #selector(cameraButtonPressed), // 2
          for: .primaryActionTriggered
        )
        
        let giphy = InputBarButtonItem(type: .system)// 1
         giphy.tintColor = .secondaryLabel
         giphy.image = UIImage.init(systemName: "photo.fill")
         giphy.addTarget(
           self,
           action: #selector(giphyButtonPressed), // 2
           for: .primaryActionTriggered
         )
        cameraItem.setSize(CGSize(width: 30, height: 30), animated: false)
        giphy.setSize(CGSize(width: 30, height: 30), animated: false)
        messageInputBar.setLeftStackViewWidthConstant(to: 85, animated: false)
        messageInputBar.setStackViewItems([cameraItem,giphy], forStack: .left, animated: false) // 3
    }
    
    @objc func giphyButtonPressed(){
        print("giphy button pressed")
        print("Send gif pressed")
        let giphy = GiphyViewController()
        
        giphy.layout = .waterfall
        giphy.mediaTypeConfig = [.gifs, .stickers, .text, .emoji]
        giphy.showConfirmationScreen = true
        giphy.theme = .dark
        giphy.delegate = self
        giphy.tabBarController?.tabBar.isHidden = true
        self.present(giphy, animated: true, completion: nil)
    }
    
    @objc func cameraButtonPressed(){
        print("camera button pressed")
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "Take photo", style: .default, handler: { (action) in
            print("take photo pressed")
        }))
        
        alertController.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action) in
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.mediaTypes = ["public.image", "public.movie"]
            picker.sourceType = .photoLibrary


            self.present(picker, animated: true, completion: nil)
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
        alertController.view.tintColor = .systemPink
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    
    func getMessageArray(){
        let docRef = db.collection("channels").document(channel?.id ?? "").collection("messages")
        let query = docRef.order(by: "sentDate", descending: true).limit(to: 30)
        
        
        chatListener = query.addSnapshotListener { (snapshot, error) in
            if error == nil{
                snapshot!.documentChanges.forEach { change in
                  self.handleDocumentChange(change)
                }
                self.refreshControl.endRefreshing()
                    //self.messageList = messages
                UIView.animate(withDuration: 0.2) {
                    DispatchQueue.main.async {
                        if self.listenerHasRan{
                            self.messagesCollectionView.reloadData()
                            self.messagesCollectionView.scrollToBottom(animated: true)
                        }else{
                        self.messagesCollectionView.reloadDataAndKeepOffset()
                        self.updateCollectionContentInset()
                        }
                        self.listenerHasRan = true
                    }
                }
                print(self.didViewAppear)
            }
        }
        
        self.messageInputBar.inputTextView.placeholder = "Say something..."
    }
    func updateCollectionContentInset() {
        let contentSize = messagesCollectionView.collectionViewLayout.collectionViewContentSize
        var contentInsetTop = messagesCollectionView.bounds.size.height

            contentInsetTop -= contentSize.height
            if contentInsetTop <= 0 {
                contentInsetTop = 0
        }
        let window = UIApplication.shared.keyWindow
        messagesCollectionView.contentInset = UIEdgeInsets(top: contentInsetTop,left: 0,bottom: (self.tabBarController?.tabBar.frame.size.height ?? 0)+(window?.safeAreaInsets.bottom ?? 0) ,right: 0)
    }
    
    
    func getAvatarFor(sender: SenderType) -> Avatar {
      
        if channel?.members.contains(sender.senderId) ?? false{
            return Avatar(image: FollowersHelper().getUserProfilePicture(), initials: "")
        }else{
            return Avatar(image: FollowersHelper().getUserProfilePicture(), initials: "")
        }
    }
    
    @objc func loadMoreMessages(){
        refreshControl.beginRefreshing()
        if let doc = lastDocument{
       let docRef = db.collection("channels").document(channel?.id ?? "").collection("messages")
        let query = docRef.order(by: "sentDate", descending: true).limit(to: 30).start(atDocument: doc)
            
            query.getDocuments { (snapshot, error) in
                if error == nil{
                    for document in snapshot!.documents{
                        self.lastDocument = document
                        let msg = Message(sender: Sender(id: "", displayName: ""), messageId: "", sentDate: Date(), kind: MessageKind.text(""))
                        msg.convertFrom(dictionary: document)
                        if !(self.channel?.messages.contains(msg))!{
                            self.channel?.messages.insert(msg, at: 0)
                            self.messagesCollectionView.reloadDataAndKeepOffset()
                        }
                    }
                    self.refreshControl.endRefreshing()
                }
            }

        }
    }
    
    private func handleDocumentChange(_ change: DocumentChange) {
      print("handle doc change channel")
      let msg = Message(sender: Sender(id: "", displayName: ""), messageId: "", sentDate: Date(), kind: MessageKind.text(""))
        lastDocument = change.document
        msg.convertFrom(dictionary: change.document)
        let lastMessageText = msg.content ?? ""
        ChatViewController.lastMessage.setValue(lastMessageText, forKey: channel?.id ?? "")
       // ChannelsViewController.channels[editingIndex].lastMessageDate =
      switch change.type {
      case .added:
        addMessageToTable(msg: msg)
        
      case .modified:
        updateMessageInTable(msg: msg)
        
      case .removed: break
        /*
        removeMessageFromTable(msg: msg)
 */
        
      }
    }
    
    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section - 1 >= 0 else { return false }
        return channel?.messages[indexPath.section].sender.senderId == channel?.messages[indexPath.section - 1].sender.senderId
    }
    
    func is4HoursApart(date1: Date, date2: Date) -> Bool{
        return date1.timeIntervalSince(date2) > 10800
    }
    
    func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section + 1 < (channel!.messages.count) else { return false }
        return channel?.messages[indexPath.section].sender.senderId == channel?.messages[indexPath.section + 1].sender.senderId
    }
    
    func isLastMessage(at indexPath: IndexPath) -> Bool{
        let newArray = channel?.messages.filter({ (msg) -> Bool in
            return msg.sender.senderId == User.shared.uid ?? ""
        })
        if newArray?.count ?? 0 > 0{
            return channel?.messages[indexPath.section] == newArray?[(newArray?.count ?? 1)-1]
        }else{
            return false
        }
    }
    
    func isTimeLabelVisible(at indexPath: IndexPath) -> Bool {
    guard indexPath.section - 1 >= 0 else { return false }
    if let date1 = channel?.messages[indexPath.section].sentDate, let date2 = channel?.messages[indexPath.section - 1].sentDate{
        
    return is4HoursApart(date1: date1, date2: date2)
        }else{
            return false
        }
    }
    
    func addMessageToTable(msg : Message){
        print("add channel to table")
        guard !(channel?.messages.contains(msg))! else {
          return
        }
        
        channel?.messages.append(msg)
        channel?.messages.sort()
        
      guard let index = channel?.messages.firstIndex(of: msg) else {
          return
        }
        if msg.sender.senderId != User.shared.uid && didViewAppear{
            AudioServicesPlaySystemSound(recievedSound)
        }
        
    /*    messagesCollectionView.performBatchUpdates({
            messagesCollectionView.insertSections(IndexSet(arrayLiteral: index))
            if index >= 1 {
                messagesCollectionView.reloadSections(IndexSet(arrayLiteral: index-1))
            }
        }) { (completion) in
            self.messagesCollectionView.scrollToBottom(animated: true)
        } */
    
    }
    func updateMessageInTable(msg : Message){
        print("update channel")
        guard let index = channel?.messages.firstIndex(of: msg) else {
          return
        }
        channel?.messages[index] = msg
    }
    func removeMessageFromTable(msg : Message){
        print("remove channel")
        if let index = channel?.messages.firstIndex(of: msg) {
            channel?.messages[index].content = "this message will be removed"
            channel?.messages[index].photoURL = ""
            channel?.messages[index].messageKind = "text"
            messagesCollectionView.reloadSections(IndexSet(integer: index))
           // messagesCollectionView.deleteSections(IndexSet(integer: index))
        }else{
            print("failed to remove message")
        }
    }
    
    @available(iOS 13.0, *)
    func configureMessageForDarkMode(){
        messageInputBar.isTranslucent = true
        messageInputBar.inputTextView.tintColor = .systemPink
       messageInputBar.inputTextView.backgroundColor = UIColor.clear
        messageInputBar.backgroundColor = .none
        messageInputBar.blurView.effect = UIBlurEffect(style: .regular)
        messageInputBar.separatorLine.backgroundColor = .separator
        
        messageInputBar.inputTextView.placeholderTextColor = .secondaryLabel
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 36)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 36)
        messageInputBar.inputTextView.layer.borderColor = UIColor.separator.cgColor
        messageInputBar.inputTextView.layer.borderWidth = 0.0
        messageInputBar.inputTextView.layer.cornerRadius = 16.0
        messageInputBar.inputTextView.layer.masksToBounds = true
        messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        messageInputBar.sendButton.setTitleColor(.systemPink, for: .normal)
        messageInputBar.sendButton.setTitleColor(.secondaryLabel, for: .disabled)
        
        self.messageInputBar.backgroundView.tintColor = .none
        self.messageInputBar.backgroundView.backgroundColor = .none
        
        
        messagesCollectionView.backgroundColor = .systemBackground
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath)
        return cell
    }
  
}


extension ChatViewController: MessagesDataSource {
    func currentSender() -> SenderType {
        return Sender(id: User.shared.uid ?? "", displayName: User.shared.name ?? "")
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        channel?.messages.count ?? 0
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return ((channel?.messages[indexPath.section])!)
    }
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if isTimeLabelVisible(at: indexPath) {
            if #available(iOS 13.0, *) {
                return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
            } else {
                // Fallback on earlier versions
                return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
            }
        }
        return nil
    }

}
extension ChatViewController : MessageCellDelegate{
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("Avatar tapped")
    }
    
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("Message tapped")
        guard let indexPath = self.messagesCollectionView.indexPath(for: cell),
            let message = self.channel?.messages[indexPath.section] else{
                return
        }
        let sent = "Sent \(MessageKitDateFormatter.shared.string(from: message.sentDate))"
        let alertController = UIAlertController(title: message.content ?? "", message: sent, preferredStyle: .actionSheet)
        
        if message.messageKind == "photo" || message.messageKind == "video" {
                if let string = message.photoURL{
                    self.showImage(string: string)
                }
          
        }else{
            if message.sender.senderId == User.shared.uid{
            alertController.addAction(UIAlertAction(title: "Unsave Message", style: .destructive, handler: { (action) in
                let ref = db.collection("channels").document(self.channel!.id ?? "").collection("messages").document(message.messageId)
              /*  if (self.channel?.messages.contains(message))!{
                    self.channel?.messages.remove(at: indexPath.row)
                    self.messagesCollectionView.deleteItems(at: [indexPath])
                } */
                ref.delete()
            }))
            }

            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                
            }))
            
            alertController.view.tintColor = .systemPink
            alertController.modalPresentationStyle = .popover
            self.present(alertController, animated: true, completion: nil)
        }
    
    }
    
    func didTapCellTopLabel(in cell: MessageCollectionViewCell) {
        print("Top cell label tapped")
    }
    
    func didTapCellBottomLabel(in cell: MessageCollectionViewCell) {
        print("Bottom cell label tapped")
    }
    
    func didTapMessageTopLabel(in cell: MessageCollectionViewCell) {
        print("Top message label tapped")
    }
    
    func didTapMessageBottomLabel(in cell: MessageCollectionViewCell) {
        print("Bottom label tapped")
    }

}
extension ChatViewController : MessageInputBarDelegate, MessageLabelDelegate, UITextViewDelegate{
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.isEmpty{
           messageInputBar.setLeftStackViewWidthConstant(to: 85, animated: true)
        }else{
           messageInputBar.setLeftStackViewWidthConstant(to: 0, animated: true)
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        messageInputBar.setLeftStackViewWidthConstant(to: 85, animated: true)
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        AudioServicesPlaySystemSound(sentSound)
        print("did press send")
        messageInputBar.setLeftStackViewWidthConstant(to: 85, animated: true)
        self.messageInputBar.inputTextView.placeholder = "Sending..."
        sendMessage(text: text, photoURL: nil, kind: "text", placeHolderURL: nil)
    }
    
    func sendMessage(text: String?, photoURL : String?, kind : String, placeHolderURL : String?){
        messageInputBar.sendButton.startAnimating()
        DispatchQueue.global(qos: .default).async {
            
        let batch = db.batch()
        let docRef = db.collection("channels").document(self.channel?.id ?? "")
        let docRef2 = docRef.collection("messages").document()
            docRef2.setData(["content" : text as Any,
                                  "messageKind":kind,
                                  "sender" : User.shared.name ?? "",
                                  "sentDate" : Timestamp.init(date: Date()),
                                  "uid" : User.shared.uid ?? "",
                                  "messageID" : docRef2.documentID,
                                  "photoURL" : photoURL as Any,
                                    "placeHolderURL" : placeHolderURL as Any
        ])
            docRef.updateData(["lastSentDate" : Timestamp(date: Date()),
            "lastSentMessage" : "Sent a message",
            "lastSentMessageID" : docRef2.documentID,
            "lastSentUser" : User.shared.uid ?? "",
            "active" : true])
            
            if let tokens = self.channel?.tokens {
                           for token in tokens{
                           let notify = PushNotificationSender()
                            if !User.shared.tokens.contains(token){
                            if self.channel?.groupChat == nil{
                                notify.sendPushNotification(to: token , title: User.shared.name ?? "", body: "New Message", tag: self.channel?.id, badge: nil)
                            }else{
                                notify.sendPushNotification(to: token , title: self.channel?.name ?? "", body: "from \(User.shared.name ?? "")", tag: self.channel?.id, badge: nil)
                            }
                            }else{
                                print("not senidng it to myself")
                            }
                            
                           }
                           }
        //let index = IndexPath(row: self.channel!.messages.count - 1, section: 0)
        DispatchQueue.main.async { [weak self] in
            batch.commit { (error) in
                
                if error == nil{
                    print("write batch successful")
                    
                    self?.messageInputBar.inputTextView.text = String()
                    self?.messageInputBar.invalidatePlugins()
                    self?.messageInputBar.inputTextView.placeholder = "Say something..."
                    self?.messageInputBar.sendButton.stopAnimating()
                }else{
                    ProgressHUD.showError("Message failed")
                    print("wirte batch errorr: \(error!)")
                }
            }
            }
        }
    }
    
    func uploadImage(_ image: UIImage?, to channel: Channel, completion: @escaping (URL?) -> Void) {
     let storage = Storage.storage().reference()
      guard let channelID = channel.id else {
        completion(nil)
        return
      }
      
        guard let data = image?.jpegData(compressionQuality: 0.5) else {
        completion(nil)
        print("there was an error")
        return
      }
      
      let metadata = StorageMetadata()
      metadata.contentType = "image/jpeg"
      
      let imageName = [UUID().uuidString, String(Date().timeIntervalSince1970)].joined()
      let imageRef = storage.child(channelID).child(imageName)
      imageRef.putData(data, metadata: metadata) { meta, error in
        if error == nil{
        imageRef.downloadURL { (url, error) in
            if error == nil{
                self.sendMessage(text: nil, photoURL: url?.absoluteString, kind: "photo", placeHolderURL: nil)
            }else{
                print("there was an error \(error!)")
            }
        }
        }else{
            print("there was an error \(error!)")
        }
      }
    }
    
    func uploadVideo(url: URL, channel : Channel, success : @escaping (String) -> Void,failure : @escaping (Error) -> Void) {
        guard let channelID = channel.id else {
          return
        }
        let name = "\(UUID().uuidString)#\(Int(Date().timeIntervalSince1970)).mp4"
        let path = NSTemporaryDirectory() + name

        let dispatchgroup = DispatchGroup()

        dispatchgroup.enter()

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputurl = documentsURL.appendingPathComponent(name)
        var ur = outputurl
        self.convertVideo(toMPEG4FormatForVideo: url as URL, outputURL: outputurl) { (session) in

            ur = session.outputURL!
            dispatchgroup.leave()

        }
        dispatchgroup.wait()

        let data = NSData(contentsOf: ur as URL)

        do {
            try data?.write(to: URL(fileURLWithPath: path), options: .atomic)

        } catch {

            print(error)
        }

        let storageRef = Storage.storage().reference().child(channelID).child(name)
        if let uploadData = data as Data? {
            storageRef.putData(uploadData, metadata: nil
                , completion: { (metadata, error) in
                    if let error = error {
                        failure(error)
                    }else{
                        storageRef.downloadURL { (downloadURL, error) in
                            if let error = error{
                             failure(error)
                            }else{
                                let imageRef = Storage.storage().reference().child("profilePics").child(User.shared.uid ?? "").child("\(UUID().uuidString)\(Date()).jpg")
                                guard let data = FollowersHelper().generateThumbnail(path: url)?.jpegData(compressionQuality: 0.1) else { return }
                                imageRef.putData(data, metadata: nil) { (metaData, error) in
                                    if error == nil{
                                    imageRef.downloadURL { (thumbnail, error) in
                                        if error == nil{
                                        print("thumb nail url downloaded successfully")
                                        self.sendMessage(text: nil, photoURL: downloadURL?.absoluteString, kind: "video", placeHolderURL: thumbnail?.absoluteString)
                                            success(downloadURL!.absoluteString)
                                        }else{
                                            failure(error!)
                                        }
                                    }
                                    }
                                }
                            }
                        }
                    }
            })
        }
    }
    
    func convertVideo(toMPEG4FormatForVideo inputURL: URL, outputURL: URL, handler: @escaping (AVAssetExportSession) -> Void) {
        //try! FileManager.default.removeItem(at: outputURL)
        let asset = AVURLAsset(url: inputURL as URL, options: nil)

        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1280x720)!
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.exportAsynchronously(completionHandler: {
            handler(exportSession)
        })
    }
}
extension ChatViewController : MessagesLayoutDelegate, MessagesDisplayDelegate{
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        let avatar = getAvatarFor(sender: message.sender)
        avatarView.set(avatar: avatar)
        if channel?.groupChat == true{
        avatarView.isHidden = isNextMessageSameSender(at: indexPath)
        }
        //avatarView.layer.borderWidth = 2
        //avatarView.layer.borderColor = UIColor.systemPink.cgColor
        if let url = channel?.profilePics?.value(forKey: message.sender.senderId) as? String{
            avatarView.kf.setImage(with: URL(string: url), placeholder: UIImage.init(named: "icons8-male-user-96"))
        }else{
            avatarView.image = FollowersHelper().getUserProfilePicture()
        }
    }

    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        
        if #available(iOS 13.0, *) {
            return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11, weight: .medium), NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
        } else {
                return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
            
            // Fallback on earlier versions
        }
    }
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        if !isNextMessageSameSender(at: indexPath){
        let tail: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(tail, .curved)
        }else{
            return .bubble
        }
    }
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if !(isFromCurrentSender(message: message)) && !(isPreviousMessageSameSender(at: indexPath)){
            return 16
        }else{
            return 0
        }
    }
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return (!isNextMessageSameSender(at: indexPath) && isFromCurrentSender(message: message) && isLastMessage(at: indexPath)) ? 16 : 0
    }
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        if channel?.messages[indexPath.section].messageKind == "photo" || channel?.messages[indexPath.section].messageKind == "video"{
            return UIColor.clear
        }else if isFromCurrentSender(message: message){
            return .systemBlue
        }else{
            if #available(iOS 13.0, *) {
                return UIColor.systemGray5
            }
            return UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
        }
    }
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        if isFromCurrentSender(message: message){
            return UIColor.white
        }else{
            if #available(iOS 13.0, *) {
                return .label
            } else {
                return UIColor.black
                // Fallback on earlier versions
            }
        }
    }
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if isTimeLabelVisible(at: indexPath) {
            return 18
        }
        return 0
    }
    
    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key: Any] {
        switch detector {
        case .hashtag, .mention: if #available(iOS 13.0, *) {
            return [.foregroundColor: UIColor.link]
        } else {
            return [.foregroundColor: UIColor.blue]
            // Fallback on earlier versions
            }
        default: return MessageLabel.defaultAttributes
        }
    }
    
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if !isNextMessageSameSender(at: indexPath) && isFromCurrentSender(message: message) && isLastMessage(at: indexPath){
            if #available(iOS 13.0, *) {
                var string = "Delivered"
                
                if let uid = channel?.getSenderID(),
                    let lastOpened = channel?.lastOpened?.value(forKey: uid) as? Timestamp,
                    let lastSent = channel?.lastMessageDate{
                    if lastOpened.dateValue() > lastSent && !(channel?.groupChat ?? false){
                        let time = "\(FollowersHelper().dayDifference(from: lastOpened.dateValue().timeIntervalSince1970))"
                        string = "Read \(time.lowercased())"
                    }else if (channel?.reading?.value(forKey: uid) as? Bool) ==  true{
                        if !(channel?.groupChat ?? false){
                            let time = "\(FollowersHelper().dayDifference(from: Date().timeIntervalSince1970))"
                            string = "Read \(time.lowercased())"
                        }
                    }
                }
                
                return NSAttributedString(string: string, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
            } else {
                // Fallback on earlier versions
                return NSAttributedString(string: "Delivered", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
            }
        }
        return nil
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
            /// if we don't have a url, that means it's simply a pending message
        if channel?.messages[indexPath.section].messageKind == "photo"{
            guard let url = channel?.messages[indexPath.section].photoURL else {
                imageView.kf.indicator?.startAnimatingView()
                return
            }
            imageView.kf.indicatorType = .activity
            imageView.kf.setImage(with: URL(string: url))
        }else if channel?.messages[indexPath.section].messageKind == "video"{
          guard let url = channel?.messages[indexPath.section].placeHolderURL else {
                imageView.kf.indicator?.startAnimatingView()
                return
            }
            let playView = UIImageView(image: UIImage(systemName: "play.circle.fill"))
            imageView.addSubview(playView)
            playView.center.x = imageView.center.x
            playView.center.y = imageView.center.y
            
            imageView.kf.indicatorType = .activity
            imageView.kf.setImage(with: URL(string: url))
        }
        
    }
    
    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .date, .transitInformation, .mention, .hashtag]
    }
    
    
}

extension ChatViewController{
    func setSetttingsButton(){
        let settings = UIButton.init(type: .custom)
        settings.tintColor = .systemPink
        settings.addTarget(self, action:#selector(settingsBarButtonPressed), for:.touchUpInside)
        settings.widthAnchor.constraint(equalToConstant: 32).isActive = true
        settings.heightAnchor.constraint(equalToConstant: 32).isActive = true
        DispatchQueue.main.async {
            if self.channel?.groupChat != nil{
            settings.kf.setImage(with: URL(string: self.url), for: .normal, placeholder: FollowersHelper().getGroupProfilePicture())
            }else{
            settings.kf.setImage(with: URL(string: self.url), for: .normal, placeholder: FollowersHelper().getUserProfilePicture())
            }
            settings.imageView?.contentMode = .scaleAspectFill
            settings.roundCorners()
        }


        let settingsButton = UIBarButtonItem.init(customView: settings)
        navigationItem.rightBarButtonItems = [settingsButton]
    }
    
    @objc func settingsBarButtonPressed(){
        print("settings bar button pressed")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ChatInfoViewController") as! ChatInfoViewController
        if let ch = channel{
        vc.channel = ch
        navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension ChatViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
      picker.dismiss(animated: true, completion: nil)
        
        if let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String {

            if mediaType  == "public.image" {
                // 1
                  let newImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
                  if let ch = self.channel,let image = newImage{
                  self.uploadImage(image, to: ch) { (url) in
                      print("image upload complete")
                  }
                    
                }
            }
            if mediaType == "public.movie" {
                print("Video Selected")
                if let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL, let ch = self.channel {
                    self.uploadVideo(url: url, channel: ch, success: { (string) in
                        print("success uploading videp")
                    }) { (error) in
                        print("error uploading video\(error)")
                    }
                    // Do something with the URL
                }
            }
        }
      print("uploading image")
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      picker.dismiss(animated: true, completion: nil)
    }
}

extension ChatViewController: LightboxControllerPageDelegate, LightboxControllerDismissalDelegate{
    func lightboxController(_ controller: LightboxController, didMoveToPage page: Int) {
        print("did move")
    }
    
    func lightboxControllerWillDismiss(_ controller: LightboxController) {
        print("did dismiss")
    }
    
    func showImage(string : String){
        // Create an array of images.
        var images : [LightboxImage] = [LightboxImage]()
        var goToIndex = 0
        var foundGoToIndex = false
        if channel != nil{
            
            guard let messages = channel?.messages.filter({ (message) -> Bool in
                return message.messageKind == "photo" || message.messageKind == "video"
            }) else { return }
            
            for message in messages{
                if let url = message.photoURL, let output = URL(string: url){
                    print("appending image index \(images.count-1)")
                    let sender = channel?.metaData?.value(forKey: message.sender.senderId) as? String
                    let date = FollowersHelper().dayDifference(from: message.sentDate.timeIntervalSince1970)
                    let text = "Sent by \(sender ?? "Unknown"), \(date)"
                    var lightboxImage = LightboxImage(imageURL: output,text:text)
                    if message.messageKind == "video"{
                        if let thumbnailString = message.placeHolderURL, let thumbnail = URL(string: thumbnailString){
                            lightboxImage = LightboxImage(imageURL: thumbnail, text:text, videoURL:output)
                        }
                    }
                    images.append(lightboxImage)
                    if url == string && !foundGoToIndex{
                    foundGoToIndex = true
                    }else if !foundGoToIndex {
                    goToIndex = goToIndex + 1
                    }
                }
            
        }
        }
        
        LightboxConfig.loadImage = {
          imageView, URL, completion in
            imageView.kf.setImage(with: URL)
            // add this line
            completion?(nil)
          // Custom image loading
        }
        
        LightboxConfig.CloseButton.text = ""
        LightboxConfig.CloseButton.size = CGSize(width: 40, height: 40)
        LightboxConfig.CloseButton.image = UIImage(systemName: "xmark.circle.fill")
        // Create an instance of LightboxController.
        let controller = LightboxController(images: images)
        print("going to page \(goToIndex)")
        controller.view.tintColor = UIColor.systemPink

        // Set delegates.
        controller.pageDelegate = self
        controller.dismissalDelegate = self

        // Use dynamic background.
        controller.dynamicBackground = true
        controller.modalPresentationStyle = .fullScreen
        // Present your controller.
        controller.tabBarController?.tabBar.isHidden = true
        present(controller, animated: true, completion: nil)
        controller.goTo(goToIndex)
    }
}

extension ChatViewController: GiphyDelegate {
    func didSelectMedia(giphyViewController: GiphyViewController, media: GPHMedia){
        // your user tapped a GIF!
        let gifURL = media.url(rendition: .fixedWidth, fileType: .gif)
        sendMessage(text: nil, photoURL: gifURL, kind: "photo", placeHolderURL: nil)
        giphyViewController.dismiss(animated: true, completion: nil)
        
   }
   func didDismiss(controller: GiphyViewController?) {
        // your user dismissed the controller without selecting a GIF.
   }
}

