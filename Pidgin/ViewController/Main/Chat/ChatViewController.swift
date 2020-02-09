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
import SafariServices
import NotificationBannerSwift
import DeepDiff
class ChatViewController: MessagesViewController {
    
    var name = ""
    
    var url = ""
    
    var chatListener : ListenerRegistration?
    
    var didViewAppear = false
    
    var editingIndex = 0

    var channel: Channel?
    
    var activityIndicator : UIActivityIndicatorView!
    
    var lastDocument : DocumentSnapshot?
    
    let sentSound: SystemSoundID = 1004
    
    let recievedSound: SystemSoundID = 1003
    
    var listenerHasRan = false
    
    var currentlyLoadingMessages = false
    
    var shouldScroll = true
    
    var loadedAllMessages = false
    
    
    static var lastMessage : NSMutableDictionary = NSMutableDictionary()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    updateLastOpened()
    let backButton = UIBarButtonItem()
    backButton.title = "" //in your case it will be empty or you can put the title of your choice
    self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
    //self.navigationController?.navigationBar.topItem?.title = " "
    //messagesCollectionView.transform = CGAffineTransform(scaleX: 1, y: -1)
    NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name:NSNotification.Name(rawValue: "reloadData"), object: nil)
    NotificationCenter.default.addObserver(self,
    selector: #selector(applicationWillEnterForeground),
    name: UIApplication.willEnterForegroundNotification,
    object: nil)
    
    NotificationCenter.default.addObserver(self,
    selector: #selector(applicationWillEnterBackground),
    name: UIApplication.willResignActiveNotification,
    object: nil)
    
    NotificationCenter.default.addObserver(self,
    selector: #selector(applicationWillTerminate),
    name: UIApplication.willTerminateNotification,
    object: nil)
    scrollsToBottomOnKeyboardBeginsEditing = true
    
    messageInputBar.delegate = self
    messagesCollectionView.delegate = self
    messagesCollectionView.messageCellDelegate = self
    messagesCollectionView.messagesDataSource = self
    messagesCollectionView.messagesLayoutDelegate = self
    messagesCollectionView.messagesDisplayDelegate = self
    self.messageInputBar.inputTextView.delegate = self

    
        if #available(iOS 13.0, *) {
               configureMessageForDarkMode()
           }
    self.activityIndicator = UIActivityIndicatorView(style: .medium)
    self.activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
    
    messagesCollectionView.addSubview(activityIndicator)
    activityIndicator.startAnimating()
    
    messageInputBar.sendButton.setSize(CGSize(width: 40, height: 40), animated: false)
    messageInputBar.setRightStackViewWidthConstant(to: 36, animated: false)
    messageInputBar.sendButton.tintColor = .systemPink
    messageInputBar.sendButton.image = UIImage(systemName: "paperplane.fill")
    messageInputBar.sendButton.title = nil
    messageInputBar.sendButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
    messageInputBar.middleContentViewPadding.right = -38
    createCameraButton()
    
    let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout
    
    layout?.emojiMessageSizeCalculator.messageLabelFont = UIFont.systemFont(ofSize: 52)
    layout?.sectionInset = UIEdgeInsets(top: 1, left: 8, bottom: 4, right: 8)
    
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
    
    maintainPositionOnKeyboardFrameChanged = true
    //messageInputBar.sendButton.setTitleColor(.primary, for: .normal)
    updateConstraints()
        setSetttingsButton()
    
  }
    
    @objc func reloadData(){
        if didViewAppear{
        if let chan = channel, let index = channels.firstIndex(of: chan){
            channel?.lastOpened = channels[index].lastOpened
            channel?.lastMessageDate = channels[index].lastMessageDate
            channel?.reading = channels[index].reading
            
        }
        if let messages = channel?.messages{
        for message in messages{
            guard let index = channel?.messages.firstIndex(of: message) else{
                return
            }
            let indexPath = IndexPath(item: index, section: 0)
            if isLastMessage(at: indexPath){
                messagesCollectionView.reloadItems(at: [indexPath])
                break
            }
        }
        }
        }
    }
    
    @objc func applicationWillEnterForeground(){
        if self.viewIfLoaded?.window != nil {
           updateLastOpened()
        }
        
    }
    
    @objc func applicationWillEnterBackground(){
        if self.viewIfLoaded?.window != nil {
           removeLastOpened()
        }
    }
    
    @objc func applicationWillTerminate(){
        if self.viewIfLoaded?.window != nil {
           removeLastOpened()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        didViewAppear = true
        shouldScroll = true
        if Auth.auth().currentUser != nil {
            print("user is signed in")
        } else {
            print("user is not signed in")
            returnToLoginScreen()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getMessageArray()
        writeLastOpened()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeLastOpened()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        chatListener?.remove()
    }
    func updateConstraints(){
        NSLayoutConstraint.activate([
        messagesCollectionView.topAnchor.constraint(equalTo: view.topAnchor),
        messagesCollectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
        messagesCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        messagesCollectionView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
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
        cameraItem.image = UIImage.init(systemName: "plus.circle")
        cameraItem.addTarget(
          self,
          action: #selector(cameraButtonPressed), // 2
          for: .primaryActionTriggered
        )
        
        let giphy = InputBarButtonItem(type: .system)// 1
         giphy.tintColor = .secondaryLabel
        giphy.setTitle("GIF", for: .normal)
        giphy.setTitleColor(.secondaryLabel, for: .normal)
        giphy.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .heavy)
         giphy.addTarget(
           self,
           action: #selector(giphyButtonPressed), // 2
           for: .primaryActionTriggered
         )
        
        cameraItem.setSize(CGSize(width: 30, height: 30), animated: false)
        giphy.setSize(CGSize(width: 30, height: 30), animated: false)
        messageInputBar.setLeftStackViewWidthConstant(to: 85, animated: false)
        messageInputBar.setStackViewItems([cameraItem,giphy], forStack: .left, animated: false) // 3
        messageInputBar.leftStackView.updateConstraintsIfNeeded()
    }
    
    @objc func giphyButtonPressed(){
        print("giphy button pressed")
        print("Send gif pressed")
        let giphy = GiphyViewController()
        
        giphy.layout = .waterfall
        giphy.mediaTypeConfig = [.gifs, .stickers, .text, .emoji]
        giphy.showConfirmationScreen = true
        if self.traitCollection.userInterfaceStyle == .dark {
            // User Interface is Dark
            giphy.theme = .dark
        } else {
            giphy.theme = .light
            // User Interface is Light
        }
        giphy.delegate = self
        giphy.tabBarController?.tabBar.isHidden = true
        giphy.hidesBottomBarWhenPushed = true
        self.tabBarController?.present(giphy, animated: true, completion: nil)
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
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    
    func getMessageArray(){
        let docRef = db.collection("channels").document(channel?.id ?? "").collection("messages")
        let query = docRef.order(by: "sentDate", descending: true).limit(to: 16)
        
        
        chatListener = query.addSnapshotListener { (snapshot, error) in
            if error == nil{
                self.handleDocumentChange(snapshot!.documents, scrollToBottom: true)
                self.activityIndicator.stopAnimating()
                
                print(self.didViewAppear)
            }
        }
        
        self.messageInputBar.inputTextView.placeholder = "Say something..."
    }
    
    
    func getAvatarFor(sender: SenderType) -> Avatar {
      
        if channel?.members.contains(sender.senderId) ?? false{
            return Avatar(image: FollowersHelper().getUserProfilePicture(), initials: "")
        }else{
            return Avatar(image: FollowersHelper().getUserProfilePicture(), initials: "")
        }
    }
    
    @objc func loadMoreMessages(){
        if didViewAppear && !loadedAllMessages && !currentlyLoadingMessages{
            activityIndicator.startAnimating()
            currentlyLoadingMessages = true
        if let doc = lastDocument{
       let docRef = db.collection("channels").document(channel?.id ?? "").collection("messages")
        let query = docRef.order(by: "sentDate", descending: true).limit(to: 16).start(afterDocument: doc)
            query.getDocuments { (snapshot, error) in
                if error == nil{
                    if snapshot!.count < 16{
                        self.loadedAllMessages = true
                    }
               //     self.handleDocumentChange(snapshot!.documents, scrollToBottom: false)
                    for document in snapshot!.documents{
                        self.lastDocument = document
                    let message = Message(sender: self.currentSender(), messageId: "", sentDate: Date(), kind: .text(""))
                    message.convertFrom(dictionary: document)
                        if !(self.channel?.messages.contains(message) ?? false){
                        self.channel?.messages.append(message)
                        }
                    }
                    self.channel?.messages.sort()
                    self.messagesCollectionView.reloadDataAndKeepOffset()
                    self.activityIndicator.stopAnimating()
                    self.currentlyLoadingMessages = false
                }
            }

        }
    }
    }
    
    private func handleDocumentChange(_ documents: [QueryDocumentSnapshot], scrollToBottom : Bool) {
      print("handle doc change channel")
         let old = channel?.messages ?? [Message]()
         var newItems = channel?.messages ?? [Message]()
        
        
        for document in documents{
      let msg = Message(sender: Sender(id: "", displayName: ""), messageId: "", sentDate: Date(), kind: MessageKind.text(""))
        lastDocument = document
        msg.convertFrom(dictionary: document)
        if !(newItems.contains(msg) ){
            newItems.append(msg)
        }
        }
        newItems.sort()
        let changes = diff(old: old, new: newItems)
        if let ch = self.channel, let index = channels.firstIndex(of: ch){
        self.channel = channels[index]
        }
        self.channel?.messages = newItems
        messagesCollectionView.reload(changes: changes, section: 0, updateData: {
        self.channel?.messages = newItems
        })
        self.messagesCollectionView.scrollToBottom(animated: true)
    }
    
    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.row - 1 >= 0 else { return false }
        return channel?.messages[indexPath.row].sender.senderId == channel?.messages[indexPath.row - 1].sender.senderId
    }
    
    func is4HoursApart(date1: Date, date2: Date) -> Bool{
        return date1.timeIntervalSince(date2) > 10800
    }
    
    func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.row + 1 < (channel!.messages.count) else { return false }
        return channel?.messages[indexPath.row].sender.senderId == channel?.messages[indexPath.row + 1].sender.senderId
    }
    
    func isLastMessage(at indexPath: IndexPath) -> Bool{
        let newArray = channel?.messages.filter({ (msg) -> Bool in
            return msg.sender.senderId == User.shared.uid ?? ""
        })
        if newArray?.count ?? 0 > 0{
            return channel?.messages[indexPath.row] == newArray?[(newArray?.count ?? 1)-1]
        }else{
            return false
        }
    }
    
    func isTimeLabelVisible(at indexPath: IndexPath) -> Bool {
    guard indexPath.row - 1 >= 0 else { return false }
    if let date1 = channel?.messages[indexPath.row].sentDate, let date2 = channel?.messages[indexPath.row - 1].sentDate{
        
    return is4HoursApart(date1: date1, date2: date2)
        }else{
            return false
        }
    }
    
    
    @available(iOS 13.0, *)
    func configureMessageForDarkMode(){
        messageInputBar.isTranslucent = false
        messageInputBar.inputTextView.tintColor = .systemPink
        messageInputBar.inputTextView.backgroundColor = .none
        messageInputBar.backgroundColor = .systemBackground
        messageInputBar.separatorLine.removeFromSuperview()
        
        messageInputBar.inputTextView.placeholderTextColor = .secondaryLabel
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 36)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 36)
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
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        print("loading more messages")
        if indexPath.row == 0{
            self.loadMoreMessages()
        
    }
    }
    
 /*   func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 0 && !loadedAllMessages{
            print("loading more messages")
            DispatchQueue.main.async {
                self.loadMoreMessages()
            }
        }
    } */
  
}


extension ChatViewController: MessagesDataSource {
    func currentSender() -> SenderType {
        return Sender(id: User.shared.uid ?? "", displayName: channel?.metaData?.value(forKey: User.shared.uid ?? "") as? String ?? (User.shared.name ?? ""))
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return 1
    }
    func numberOfItems(inSection section: Int, in messagesCollectionView: MessagesCollectionView) -> Int {
        return channel?.messages.count ?? 0
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return ((channel?.messages[indexPath.row])!)
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
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ExploreViewController") as! ExploreViewController
        vc.isUserProfile = true
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else{
            return
        }
        guard let message = channel?.messages[indexPath.row] else{
            return
        }
        let docRef = db.collection("users").document(message.sender.senderId)
        docRef.getDocument { (snapshot, error) in
            let user = Account()
            user.convertFromDocument(dictionary: snapshot!)
            vc.user = user
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("Message tapped")
        guard let indexPath = self.messagesCollectionView.indexPath(for: cell),
            let message = self.channel?.messages[indexPath.row] else{
                return
        }
        let sent = "Sent \(MessageKitDateFormatter.shared.string(from: message.sentDate))"
        let alertController = UIAlertController(title: message.content ?? "", message: sent, preferredStyle: .actionSheet)
        
        
        if message.messageKind == "photo" || message.messageKind == "video" {
                if let string = message.photoURL{
                    self.showImage(string: string)
                }
          
        }else{
            if let string = message.content, let url = URL(string: string){
                if UIApplication.shared.canOpenURL(url){
                alertController.addAction(UIAlertAction(title: "Open Link", style: .default, handler: { (action) in
                    self.didSelectURL(url)
                }))
                }
            }
            if message.sender.senderId == User.shared.uid{
            alertController.addAction(UIAlertAction(title: "Unsave Message", style: .destructive, handler: { (action) in
                let ref = db.collection("channels").document(self.channel!.id ?? "").collection("messages").document(message.messageId)
              /*  if (self.channel?.messages.contains(message))!{
                    self.channel?.messages.remove(at: indexPath.row)
                    self.messagesCollectionView.deleteItems(at: [indexPath])
                } */
                ref.delete()
                if let url = message.photoURL{
                FollowersHelper.deleteImage(at: url)
                }
                if let url = message.placeHolderURL{
                               FollowersHelper.deleteImage(at: url)
                               }
                    let leftView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
                leftView.image = UIImage(systemName: "checkmark.circle.fill")
                    leftView.contentMode = .scaleAspectFill
                    leftView.clipsToBounds = true
                    leftView.layer.cornerRadius = leftView.frame.height/2
                leftView.tintColor = .white
                    
                    let banner = NotificationBanner(title: "Message Unsaved", subtitle: "Message will disappear after you exit the chat", leftView: leftView, rightView: nil, style: .info, colors: CustomBannerColors())
                banner.duration = 2.5
                banner.show()
                           
                
            }))
            }

            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                
            }))
            
            alertController.view.tintColor = .systemBlue
            alertController.modalPresentationStyle = .popover
            shouldScroll = false
            self.present(alertController, animated: true, completion: nil)
        }
    
    }
    
    func didSelectURL(_ url: URL) {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        let vc = SFSafariViewController(url: url, configuration: config)
        vc.preferredControlTintColor = .systemPink
        shouldScroll = false
        self.present(vc, animated: true)
    }
    func didSelectAddress(_ addressComponents: [String : String]) {
        print("selected address")
    }
    func didSelectDate(_ date: Date) {
        print("selected date")
    }
    func didSelectPhoneNumber(_ phoneNumber: String) {
        print("selected phone number")
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
        let string = text.trimmingCharacters(in: .whitespaces)
        messageInputBar.setLeftStackViewWidthConstant(to: 85, animated: true)
        self.messageInputBar.inputTextView.placeholder = "Sending..."
        sendMessage(text: string, photoURL: nil, kind: "text", placeHolderURL: nil)
    }
    
    func sendMessage(text: String?, photoURL : String?, kind : String, placeHolderURL : String?){
        messageInputBar.sendButton.startAnimating()
        DispatchQueue.global(qos: .default).async {
            
        let batch = db.batch()
        let docRef = db.collection("channels").document(self.channel?.id ?? "")
        let docRef2 = docRef.collection("messages").document()
            
            batch.setData(["content" : text as Any,
                                      "messageKind":kind,
                                      "sender" : User.shared.name ?? "",
                                      "sentDate" : Timestamp.init(date: Date()),
                                      "uid" : User.shared.uid ?? "",
                                      "messageID" : docRef2.documentID,
                                      "photoURL" : photoURL as Any,
                                        "placeHolderURL" : placeHolderURL as Any
            ], forDocument: docRef2)
            
            batch.updateData(["lastSentDate" : Timestamp(date: Date()),
            "lastSentMessage" : "Sent a message",
            "lastSentMessageID" : docRef2.documentID,
            "lastSentUser" : User.shared.uid ?? "",
            "active" : true], forDocument: docRef)
            
        //let index = IndexPath(row: self.channel!.messages.count - 1, section: 0)
        DispatchQueue.main.async { [weak self] in
            batch.commit { (error) in
                
                if error == nil{
                    print("write batch successful")
                    if let tokens = self?.channel?.tokens {
                    for token in tokens{
                    let notify = PushNotificationSender()
                     if !User.shared.tokens.contains(token){
                        if self?.channel?.groupChat == nil{
                            notify.sendPushNotification(to: token , title: User.shared.name ?? "", body: "New Message", tag: self?.channel?.id, badge: nil)
                     }else{
                            notify.sendPushNotification(to: token , title: self?.channel?.name ?? "", body: "from \(User.shared.name ?? "")", tag: self?.channel?.id, badge: nil)
                     }
                     }else{
                         print("not senidng it to myself")
                     }
                     
                    }
                    }
                    
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
        VideoHelper.convertVideo(toMPEG4FormatForVideo: url as URL, outputURL: outputurl) { (session) in

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
            DispatchQueue.main.async {
                avatarView.kf.setImage(with: URL(string: url), placeholder: UIImage.init(named: "icons8-male-user-96"))
            }
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
        if channel?.messages[indexPath.row].messageKind == "photo" || channel?.messages[indexPath.row].messageKind == "video" ||
            (channel?.messages[indexPath.row].content?.containsOnlyEmoji ?? false &&
                channel?.messages[indexPath.row].content?.count ?? 0<=3){
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
            if message.sender.senderId == User.shared.uid{
             return [.foregroundColor: UIColor.white]
            }else{
                return [.foregroundColor: UIColor.label]
            }
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
                        let time = lastOpened.dateValue().getElapsedInterval()
                        string = "Read \(time)"
                    }else if (channel?.reading?.value(forKey: uid) as? Bool) ==  true{
                        if !(channel?.groupChat ?? false){
                            let time = Date().getElapsedInterval()
                            string = "Read \(time)"
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
        if channel?.messages[indexPath.row].messageKind == "photo"{
            guard let url = channel?.messages[indexPath.row].photoURL else {
                imageView.kf.indicator?.startAnimatingView()
                return
            }
            imageView.kf.indicatorType = .activity
            DispatchQueue.main.async {
                imageView.kf.setImage(with: URL(string: url))
            }
            imageView.heroID = url
        }else if channel?.messages[indexPath.row].messageKind == "video"{
          guard let url = channel?.messages[indexPath.row].placeHolderURL else {
                imageView.kf.indicator?.startAnimatingView()
                return
            }
            let playView = UIImageView(image: UIImage(systemName: "play.circle.fill"))
            imageView.addSubview(playView)
            playView.center.x = imageView.center.x
            playView.center.y = imageView.center.y
            
            imageView.kf.indicatorType = .activity
            DispatchQueue.main.async {
                imageView.kf.setImage(with: URL(string: url))
            }
        }
        
    }
    
    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .transitInformation]
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
                DispatchQueue.main.async {
                    settings.kf.setImage(with: URL(string: self.url), for: .normal, placeholder: FollowersHelper().getGroupProfilePicture())
                }
            }else{
                DispatchQueue.main.async {
                    settings.kf.setImage(with: URL(string: self.url), for: .normal, placeholder: FollowersHelper().getUserProfilePicture())
                }
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
                    let date = message.sentDate.getElapsedInterval()
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
        shouldScroll = false
        self.presentLightBoxController(images: images, goToIndex: goToIndex)
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
