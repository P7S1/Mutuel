//
//  SendToUserViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 12/22/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit

class SendToUserViewController: UIViewController {
    var selectedChannels : [Channel] = [Channel]()
    var selectedUsers : [Account] = [Account]()
    var allChannels : [Channel] = [Channel]()
    var allUsers : [Account] = [Account]()
    var video : URL?
    var image = UIImage()
    
    @IBOutlet weak var addToTimelineButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendingToLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    
    var addToTimeline : Bool = false
    
    let sendButton = UIButton.init(type: .custom)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        addToTimelineButton.roundCorners()
        navigationItem.title = "Share"
        setDismissButton()
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        if video != nil{
            //do stuff if it's a video
        }else{
            imageView.image = image
        }
        // Do any additional setup after loading the view.

        textView.addDoneButtonOnKeyboard()
        textView.text = "Write a caption..."
        textView.textColor = UIColor.secondaryLabel
        textView.backgroundColor = UIColor.secondarySystemBackground
        textView.clipsToBounds = true
        textView.layer.cornerRadius = 10
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        setUpSendButton()
        populateTableView()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func populateTableView(){
        let channelsRef = db.collection("channels").whereField("members", arrayContains: User.shared.uid ?? "").limit(to: 5).order(by: "lastSentDate", descending: true)
        
        channelsRef.getDocuments { (snapshot, error) in
            if error == nil{
                for document in snapshot!.documents{
                    if let channel = Channel(document: document){
                        self.allChannels.append(channel)
                    }
            }
                self.tableView.reloadData()
                self.updateSendingToLabel()
            }
        }
        let usersRef = db.collection("users").whereField("following", arrayContains: User.shared.uid ?? "").limit(to: 10)
        usersRef.getDocuments { (snapshot, error) in
            if error == nil{
                for document in snapshot!.documents{
                    let user = User()
                    user.convertFromDocument(dictionary: document)
                    self.allUsers.append(user)
            }
                self.tableView.reloadData()
                self.updateSendingToLabel()
            }
        }
    }
    
    func updateSendingToLabel(){
        var names = [String]()
        
        for user in selectedUsers{
            names.append(user.username ?? "")
        }
        
        for channel in selectedChannels{
            if channel.groupChat ?? false{
                names.append(channel.name ?? "")
            }else{
                names.append(channel.metaData?.value(forKey: channel.getSenderID() ?? "") as? String ?? "")
            }
        }
        names.sort()
        var output = ""
        var count = 0
        while count < 3 && count < names.count && names.count > 0 {
            count = count + 1
            if names.count > 1{
            output = "\(output), \(names[count-1])"
            }else{
                output = "\(names[count-1])"
            }
        }
        if names.count > 3{
            output = "\(output) + \(names.count-count) more"
        }
        sendingToLabel.text = "Sending to \(output)"
        if names.count == 0{
            sendingToLabel.text = "Select where to share to"
        }
        sendButton.isEnabled = !(names.count == 0) || addToTimeline
    }
    
    @IBAction func addToTimelineButtonPressed(_ sender: Any) {
        if !addToTimeline{
            addToTimelineButton.setTitle("Undo", for: .normal)
            addToTimelineButton.setTitleColor(.systemPink, for: .normal)
            addToTimelineButton.backgroundColor = .systemGray6
        }else{
            addToTimelineButton.setTitle("Add to my timeline", for: .normal)
            addToTimelineButton.setTitleColor(.white, for: .normal)
            addToTimelineButton.backgroundColor = .systemPink
        }
        addToTimeline.toggle()
        updateSendingToLabel()
    }
    
    @objc func sendPressed(){
        print("send pressed")
        self.view.window!.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    func setUpSendButton(){
        sendButton.setTitle("Save", for: .normal)
        sendButton.setTitleColor(.systemPink, for: .normal)
        sendButton.setTitleColor(UIColor.placeholderText, for: .disabled)
        sendButton.addTarget(self, action:#selector(sendPressed), for:.touchUpInside)
        let sendBarButton = UIBarButtonItem.init(customView: sendButton)
        navigationItem.rightBarButtonItems = [sendBarButton]
    }
    

}

extension SendToUserViewController : UITextViewDelegate{
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.secondaryLabel {
            textView.text = nil
            textView.textColor = UIColor.label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Write a caption..."
            textView.textColor = UIColor.secondaryLabel
        }
    }
    
}

extension SendToUserViewController : UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
        if indexPath.section == 0{
            let channel = allChannels[indexPath.row]
            if selectedChannels.contains(channel){
                selectedChannels.removeAll { (ch) -> Bool in
                    return channel == ch
                }
                cell.accessoryType = .none
            }else{
               cell.accessoryType = .checkmark
                selectedChannels.append(channel)
            }
        }else{
            let user = allUsers[indexPath.row]
            if selectedUsers.contains(user){
                selectedUsers.removeAll { (person) -> Bool in
                    return user == person
                }
               cell.accessoryType = .none
            }else{
               cell.accessoryType = .checkmark
                selectedUsers.append(user)
            }
        }
        }
        updateSendingToLabel()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            return allChannels.count
        }
        return allUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchUserTableViewCell", for: indexPath) as! SearchUserTableViewCell
        
        if indexPath.section == 0{
            let channel = allChannels[indexPath.row]
            if channel.groupChat ?? false{
                cell.displayName.text = channel.name
                if let id = channel.id,
                    let url = channel.profilePics?.value(forKey: id) as? String{
                    cell.profilePic.kf.setImage(with: URL(string: url), placeholder: FollowersHelper().getUserProfilePicture())
                }else{
                    cell.profilePic.image = FollowersHelper().getGroupProfilePicture()
                }
            }else{
                cell.displayName.text = channel.metaData?.value(forKey: channel.getSenderID() ?? "") as? String ?? ""
                if let url = channel.profilePics?.value(forKey: channel.getSenderID() ?? "") as? String{
                    cell.profilePic.kf.setImage(with: URL(string: url), placeholder: FollowersHelper().getUserProfilePicture())
                }else{
                    cell.profilePic.image = FollowersHelper().getUserProfilePicture()
                }
            }
            if selectedChannels.contains(channel){
                cell.accessoryType = .checkmark
            }else{
                cell.accessoryType = .none
            }
        }else{
            let user = allUsers[indexPath.row]
            cell.displayName.text = user.name ?? ""
            cell.profilePic.kf.setImage(with: URL(string: user.profileURL ?? ""), placeholder: FollowersHelper().getUserProfilePicture())
            if selectedUsers.contains(user){
                cell.accessoryType = .checkmark
            }else{
                cell.accessoryType = .none
            }
        }
        

        
        cell.username.text = ""
        cell.profilePic.clipsToBounds = true
        cell.profilePic.layer.cornerRadius = cell.profilePic.bounds.height/2
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0{
        return getHeaderView(with: "Recent Chats", tableView: tableView)
        }else{
         return getHeaderView(with: "Followers", tableView: tableView)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
}
