//
//  CreateGroupViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 11/15/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import CropViewController
import FirebaseFirestore
import DeepDiff
import BubblePictures
class CreateGroupViewController: UIViewController{
    @IBOutlet weak var createGroupButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var membersCountLogo: UILabel!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    
    
    var channel : Channel =  Channel(id: "", name: "")
    
    var mode = ""
    
    var results : [Relationship] = [Relationship]()
    
    var members : [String] = [(User.shared.uid!)]
    
    var imageURL : String?
    
    var lastDocument : DocumentSnapshot?
    
    let queryLimit = 25
    
    var loadedAllDocs = false
    
    private var bubblePictures: BubblePictures!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        NotificationCenter.default.addObserver(self, selector: #selector(presentNotification), name: NSNotification.Name(rawValue: "presentNotification"), object: nil)
        errorLabel.isHidden = true
   
        createGroupButton.roundCorners()
        tableView.delegate = self
        tableView.dataSource = self
        setUpForGroup()
        getUsersFollowers()
        updateMembersText()
        textField.addDoneButtonOnKeyboard()
        
        // Do any additional setup after loading the view.
    }
    
    func setUpBubblePictures(){
        var bubblePics = [BPCellConfigFile]()
        
        let layoutConfigurator = BPLayoutConfigurator(
        backgroundColorForTruncatedBubble: UIColor.gray,
        fontForBubbleTitles: UIFont(name: "HelveticaNeue-Light", size: 16.0)!,
        colorForBubbleBorders: UIColor.white,
        colorForBubbleTitles: UIColor.white,
        maxCharactersForBubbleTitles: 2,
        maxNumberOfBubbles: 5,
        displayForTruncatedCell: BPTruncatedCellDisplay.number(4),
        direction: .leftToRight,
        alignment: .center)
        
        for member in members{
            let relationshipMember = results.first { (relationship) -> Bool in
                return relationship.follower == member && member != User.shared.uid
            }
            print(members.count)
            
            if let string = relationshipMember?.followerProfileURL, let url = URL(string: string){
                let bubble = BPCellConfigFile(imageType: .URL(url), title: "")
            print("append a bubble")
            bubblePics.append(bubble)
            }
        }
        
        self.bubblePictures = BubblePictures(collectionView: collectionView, configFiles: bubblePics, layoutConfigurator: layoutConfigurator)
        
        collectionView.reloadData()
    }
    
    func showError(msg : String){
        errorLabel.text = msg
        errorLabel.isHidden = false
        ProgressHUD.showError(msg)
    }
    
    func setUpForGroup(){
        switch mode {
        case "editing":
            print("editing")
            navigationItem.title = "\(channel.name )"
            textField.text = channel.name
        default:
            navigationItem.title = "Create Group"
        }
    }
    
    func getUsersFollowers(){
        if let id = User.shared.uid{
        var query = db.collectionGroup("relationships").whereField("followed", isEqualTo: id).limit(to: queryLimit).order(by: "creationDate")
            if let lastDoc = self.lastDocument{
                query = query.start(afterDocument: lastDoc)
            }
        query.getDocuments { (snapshot, error) in
            if error == nil{
                let old = self.results
                var new = self.results
                
                for document in snapshot!.documents{
                    let relation = Relationship(document: document)
                    self.lastDocument = document
                    if snapshot!.count < self.queryLimit{
                        self.loadedAllDocs = true
                    }
                    if self.mode == "editing"{
                        if self.channel.members.contains(relation.follower){
                            self.members.append(relation.follower)
                        }
                    }
                    new.append(relation)
                    
                    
                }
                
                let changes = diff(old: old, new: new)
                self.tableView.reload(changes: changes, section: 0, updateData: {
                    self.results = new
                    self.updateMembersText()
                })
                
            }else{
                print("there was an error \(error!)")
            }
        }
        }
    }
    
    func updateMembersText(){
        membersCountLogo.text = "\(members.count)/10 members"
        if members.count > 2{
            createGroupButton.isEnabled = true
            createGroupButton.alpha = 1
            createGroupButton.backgroundColor = .systemPink
            if mode == "editing"{
            createGroupButton.setTitle("Done", for: .normal)
            }else{
            createGroupButton.setTitle("Start Chatting", for: .normal)
            }
            
        }else{
            createGroupButton.isEnabled = false
            createGroupButton.alpha = 0.5
            if #available(iOS 13.0, *) {
                createGroupButton.backgroundColor = .systemGray6
            } else {
                createGroupButton.backgroundColor = .lightGray
            }
            createGroupButton.setTitle("Add \(3 - members.count) more members", for: .normal)
        }
        createGroupButton.setTitleColor(UIColor.label, for: .normal)
        
        setUpBubblePictures()
    }
    
    
    @IBAction func createGroupButtonPressed(_ sender: Any) {
        print("Create group button pressed")
        if members.count >= 3{
        let isTextFieldEmpty = textField.text?.isEmpty ?? true
        if isTextFieldEmpty{
            showError(msg: "Group name field can't be left blank")
        }else{
           
            var docRef = db.collection("channels").document()
            
            if mode == "editing"{

                docRef = db.collection("channels").document(channel.id)
                
            }
            
            docRef.setData(["members":members,
               "name": textField.text ?? "",
               "groupChat": true],merge : true)
            
            let vc = ChatViewController()
            vc.channel = self.channel
            
            let navArray:Array = (self.navigationController?.viewControllers)!
            
            if mode == "editing"{
            navigationController?.popToViewController(navArray[navArray.count-3], animated: true)
            }else{
                var chan = Channel(id: docRef.documentID, name: textField.text ?? "")
                chan.groupChat = true
                
                
                vc.channel = chan
                navigationController?.pushViewController(vc, animated: true)
                var navArray:Array = (self.navigationController?.viewControllers)!
                navArray.remove(at: navArray.count-2)
                navArray.remove(at: navArray.count-2)
                self.navigationController?.viewControllers = navArray
            }
    
            
        }
        }else{
            showError(msg: "You need atleast 3 members (including youself)")
        }
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


extension CreateGroupViewController : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == results.count && !self.loadedAllDocs{
            self.getUsersFollowers()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchUserTableViewCell", for: indexPath) as! SearchUserTableViewCell
        
        let relation = results[indexPath.row]
        
        if self.channel.members.contains(relation.follower){
            cell.accessoryType = .checkmark
        }else{
            cell.accessoryType = .none
        }
        cell.displayName.text = results[indexPath.row].followerUsername
        cell.username.text = ""
        cell.profilePic.kf.setImage(with: URL(string: relation.followerProfileURL), placeholder: FollowersHelper().getUserProfilePicture())
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
        if let cell = tableView.cellForRow(at: indexPath) {
            let relation = results[indexPath.row]
            if members.contains(relation.follower){
                cell.accessoryType = .none
                let index = members.firstIndex(of: relation.follower)!
                    if let index2 = channel.members.firstIndex(of: relation.follower){
                    channel.members.remove(at: index2)
                    }
                members.remove(at: index)
            }else{
                if members.count < 10{
            cell.accessoryType = .checkmark
                    members.append(relation.follower)
                }else{
                    showError(msg: "Max 10 members allowed")
                }
            }
         updateMembersText()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 45
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return getHeaderView(with: "Select up to 10 members", tableView: tableView)
    }
    
    
}

