//
//  ChatInfoViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 11/19/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import Lightbox
class ChatInfoViewController: UIViewController {
    
    @IBOutlet weak var leaveGroupButton: UIButton!
    
    @IBOutlet weak var muteMessages: UISwitch!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var viewTitle = ""
    
    var displayname = ""
    
    @IBOutlet weak var image: UIImageView!
    
    @IBOutlet weak var addMemberButton: UIButton!
    
    var channel : Channel!
    
    var bubblePictures : BubblePictures!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        NotificationCenter.default.addObserver(self, selector: #selector(presentNotification), name: NSNotification.Name(rawValue: "presentNotification"), object: nil)
        if let index = channel.members.firstIndex(of: User.shared.uid ?? ""){
        channel.members.remove(at: index)
        }
        
        
        navigationItem.title = "Chat info"
        
        tableView.delegate = self
        tableView.dataSource = self
        
        leaveGroupButton.roundCorners()
        addMemberButton.roundCorners()
        if #available(iOS 13.0, *) {
            leaveGroupButton.backgroundColor = .systemGray6
            leaveGroupButton.setTitleColor(.systemBlue, for: .normal)
            addMemberButton.backgroundColor = .systemGray6
            addMemberButton.setTitleColor(.systemBlue, for: .normal)
        }
        
        if channel.groupChat {
            displayname = channel.name 
            leaveGroupButton.setTitle("Leave Group", for: .normal)
            addMemberButton.setTitle("Edit Group", for: .normal)
            setUpBubblePictures()
        }else{
            if let url = channel.profilePics.value(forKey: channel.members[0]) as? String{
                image.kf.setImage(with: URL(string: url), placeholder: FollowersHelper().getUserProfilePicture())
                image.heroID = url
            }else{
                image.image = FollowersHelper().getUserProfilePicture()
            }
            if channel.members.count > 0{
                displayname = channel.metaData[channel.members[0]] as? String ?? ""
                addMemberButton.setTitle("Start Group", for: .normal)
            }
            leaveGroupButton.setTitle("Block User", for: .normal)
        }
        image.layer.cornerRadius = image.bounds.height/2
        image.clipsToBounds = true
        image.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleProfilePictureTap))
        image.addGestureRecognizer(gesture)
        
        self.setUpBubblePictures()
        // Do any additional setup after loading the view.
    }
    
    
    
    @objc func handleProfilePictureTap(){
        print("tap gesture profile picture")
        if channel.groupChat {
            
            if let string = channel.profilePics.value(forKey: channel.id ?? "") as? String,
                let url = URL(string: string){
                let image = LightboxImage(imageURL: url)
                presentLightBoxController(images: [image], goToIndex: nil)
            }
            
        }else{
            
            if let string = channel.profilePics.value(forKey: channel.getSenderID() ?? "") as? String,
                let url = URL(string: string){
                let image = LightboxImage(imageURL: url)
                presentLightBoxController(images: [image], goToIndex: nil)
            }
            
        }
        
    }
    
    @IBAction func leaveGroupButtonPressed(_ sender: Any) {
        print("leave group pressed")
        
        if channel.groupChat {
            let alert = UIAlertController(title: "Leave \(displayname)", message: "Are you sure you want to leave \(displayname)?. You will have to be added again", preferredStyle: .alert)
            
            alert.popoverPresentationController?.sourceView = self.view
            alert.popoverPresentationController?.sourceRect = self.leaveGroupButton.frame
            
            alert.addAction(UIAlertAction(title: "Leave", style: .default, handler: { (action) in
            print("user leaving group")
            FollowersHelper().leaveChat(channel: self.channel)
            self.navigationController?.popToRootViewController(animated: true)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                print("user cancelled")
            }))
            self.present(alert, animated: true, completion: nil)
        }else{
            let alert = UIAlertController(title: "Block \(self.displayname)", message: "Are you sure you want to block \(self.displayname)? This will make you both unfollow each other.", preferredStyle: .alert)
            alert.popoverPresentationController?.sourceView = self.view
            alert.popoverPresentationController?.sourceRect = self.leaveGroupButton.frame
            alert.addAction(UIAlertAction(title: "Block", style: .default, handler: { (action) in
                
                let docRef = db.collection("users").document(self.channel.getSenderID())
                
                docRef.getDocument { (document, error) in
                    let user = Account()
                    user.convertFromDocument(dictionary: document!)
                    let blockedUser = BlockedUser(user: user)
                    blockedUser.blockUser { (completion) in
                        if completion{
                            ProgressHUD.showSuccess("User Blocked Successfully")
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    }
                }
                
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                print("user cancelled")
            }))
            self.present(alert, animated: true, completion: nil)
            
        }
    }
    
    @IBAction func addMemberButtonPressed(_ sender: Any) {
        print("add member button pressed")
       let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CreateGroupViewController") as! CreateGroupViewController
        if channel.groupChat {
         vc.mode = "editing"
        }
        vc.channel = channel
        vc.members = channel.members
        navigationController?.pushViewController(vc, animated: true)
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ChatInfoViewController : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channel.members.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchUserTableViewCell", for: indexPath) as! SearchUserTableViewCell
        
        
        cell.displayName.text = channel.metaData[channel.members[indexPath.row]] as? String
        cell.username.text = ""
        
        if let url = channel.profilePics.value(forKey: channel.members[indexPath.row]) as? String{
            cell.profilePic.kf.setImage(with: URL(string: url), placeholder: FollowersHelper().getUserProfilePicture())
        }else{
            cell.profilePic.image = FollowersHelper().getUserProfilePicture()
        }
        cell.profilePic.layer.cornerRadius = cell.profilePic.bounds.height/2
        cell.profilePic.clipsToBounds = true
        // Configure the cell...

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ExploreViewController") as! ExploreViewController
        vc.isUserProfile = true
        
            let docRef = db.collection("users").document(channel.members[indexPath.row])
            
            docRef.getDocument { (snapshot, error) in
                if error == nil{
                    let user = Account()
                    user.convertFromDocument(dictionary: snapshot!)
                    vc.user = user
                    self.navigationController?.pushViewController(vc, animated: true)
                }else{
                    print("there was an error \(error!)")
                }
            }
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return getHeaderView(with: "Members", tableView: tableView)
    }
    
    func setUpBubblePictures(){
        self.image.isHidden = true
        var bubblePics = [BPCellConfigFile]()
        
        let layoutConfigurator = BPLayoutConfigurator(
        backgroundColorForTruncatedBubble: UIColor.secondarySystemBackground,
        fontForBubbleTitles: UIFont(name: "AvenirNext-Medium", size: 17
        )!,
        colorForBubbleBorders: UIColor.clear,
        colorForBubbleTitles: UIColor.label,
        maxCharactersForBubbleTitles: 2,
        maxNumberOfBubbles: 10,
        displayForTruncatedCell: BPTruncatedCellDisplay.number(channel.members.count-10),
        direction: .leftToRight,
        alignment: .center)
        
        for member in channel.members{
            
            if let string = channel.profilePics.value(forKey: member) as? String,
                let url = URL(string: string){
                    let bubble = BPCellConfigFile(imageType: .URL(url), title: "")
            bubblePics.append(bubble)
            }else{
                    let bubble = BPCellConfigFile(imageType: .image(FollowersHelper().getUserProfilePicture()), title: "")
                    bubblePics.append(bubble)
            }
            
        }
        print("NEW BUBBLE PICS:")
        for pic in bubblePics{
            print(pic.title)
        }
        
        self.bubblePictures = BubblePictures(collectionView: collectionView, configFiles: bubblePics, layoutConfigurator: layoutConfigurator)

    }
    
}
