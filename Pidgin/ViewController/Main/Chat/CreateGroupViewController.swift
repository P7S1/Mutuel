//
//  CreateGroupViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 11/15/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import CropViewController
class CreateGroupViewController: UIViewController{
    @IBOutlet weak var createGroupButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var membersCountLogo: UILabel!
    
    @IBOutlet weak var image: UIButton!
    
    
    var channel = Channel(name: "")
    
    var mode = ""
    
    var results : [Account] = [Account]()
    
    var members : [Account] = [User.shared]
    
    var imageURL : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(presentNotification), name: NSNotification.Name(rawValue: "presentNotification"), object: nil)
        errorLabel.isHidden = true
        createGroupButton.roundCorners()
        tableView.delegate = self
        tableView.dataSource = self
        setUpForGroup()
        getUsersFollowers()
        updateMembersText()
        textField.addDoneButtonOnKeyboard()

        setUpProfilePicture()
        
        // Do any additional setup after loading the view.
    }
    
    func setUpProfilePicture(){
        image.roundCorners()
        image.imageView?.contentMode = .scaleAspectFill
        if let string = channel.id, let urlString = channel.profilePics?.value(forKey: string) as? String{
            image.kf.setImage(with: URL(string: urlString), for: .normal, placeholder: FollowersHelper().getGroupProfilePicture())
        }else{
            image.setImage(FollowersHelper().getGroupProfilePicture(), for: .normal)
        }
    }
    
    @IBAction func didTapProfilePicture(_ sender: Any) {
        print("did recognize tap")
        let alertController = UIAlertController(title: nil, message: nil , preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { (action) in
            print("chose take photo")
            
        }))
           
           alertController.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action) in
               print("chose choose from camera roll")
               
               let myPickerController = UIImagePickerController()
               myPickerController.delegate = self
               myPickerController.sourceType = UIImagePickerController.SourceType.photoLibrary
            myPickerController.view.tintColor = .systemPink
               self.present(myPickerController, animated: true, completion: nil)
               
           }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.view.tintColor = .systemBlue
           self.present(alertController, animated: true, completion: nil)
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
            navigationItem.title = "\(channel.name ?? "")"
            textField.text = channel.name
        default:
            navigationItem.title = "Create Group"
        }
    }
    
    func getUsersFollowers(){
        if let id = User.shared.uid{
        let query = db.collection("users").whereField("following", arrayContains: id).limit(to: 10)
        query.getDocuments { (snapshot, error) in
            if error == nil{
                for document in snapshot!.documents{
                    let account = Account()
                    account.convertFromDocument(dictionary: document)
                    if self.mode == "editing"{
                        if self.channel.members.contains(account.uid ?? ""){
                            self.members.append(account)
                            print("found match")
                        }
                    }
                    self.results.append(account)
                    self.updateMembersText()
                }
                self.tableView.reloadData()
            }else{
                print("there was an error \(error!)")
            }
        }
        }
    }
    
    func updateMembersText(){
        membersCountLogo.text = "\(members.count)/30 members"
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
        createGroupButton.setTitleColor(UIColor.white, for: .normal)
    }
    
    
    @IBAction func createGroupButtonPressed(_ sender: Any) {
        print("Create group button pressed")
        if members.count >= 3{
        let isTextFieldEmpty = textField.text?.isEmpty ?? true
        if isTextFieldEmpty{
            showError(msg: "Group name field can't be left blank")
        }else{
            var tokens = [String]()
            var metaData = NSMutableDictionary()
            var profileURLs = NSMutableDictionary()
            var memberList = [String]()
            
            if (channel.metaData != nil) && mode == "editing"{
                metaData = channel.metaData!
            }
            
            if (channel.profilePics != nil) && mode == "editing"{
                profileURLs = channel.profilePics!
            }
            for member in members{
                if let id = member.uid{
                tokens = Array(Set(tokens + member.tokens))
                metaData.setValue(member.name, forKey: id)
                profileURLs.setValue(member.profileURL, forKey: id)
                memberList.append(id)
                }
            }
            
            if mode == "editing"{
                tokens = Array(Set(channel.tokens + tokens))
                memberList = Array(Set(channel.members + memberList))
            }
           
            var docRef = db.collection("channels").document()
            if mode == "editing"{
                if let id = channel.id{
                docRef = db.collection("channels").document(id)
                }
            }
            
            docRef.setData(["fcmToken":tokens,
               "members":memberList,
               "metaData": metaData,
               "profilePicURLs" : profileURLs,
               "name": textField.text ?? "",
               "groupChat": true],merge : true)
            
            var channel = Channel(name: textField.text ?? "")
            channel.metaData = metaData
            channel.profilePics = profileURLs
            channel.groupChat = true
            channel.id = docRef.documentID
            
            let vc = ChatViewController()
            vc.channel = channel
            
            let navArray:Array = (self.navigationController?.viewControllers)!
            
            if mode == "editing"{
            navigationController?.popToViewController(navArray[navArray.count-3], animated: true)
            }else{
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchUserTableViewCell", for: indexPath) as! SearchUserTableViewCell
        
        if self.channel.members.contains(results[indexPath.row].uid ?? ""){
            cell.accessoryType = .checkmark
        }else{
            cell.accessoryType = .none
        }
        
        
        cell.displayName.text = results[indexPath.row].name ?? ""
        cell.username.text = "@\(results[indexPath.row].username ?? "")"
        if let url = results[indexPath.row].profileURL{
            cell.profilePic.kf.setImage(with: URL(string: url), placeholder: FollowersHelper().getUserProfilePicture())
            cell.profilePic.layer.cornerRadius = cell.profilePic.bounds.height/2
            cell.profilePic.clipsToBounds = true
        }else{
            cell.profilePic.image = FollowersHelper().getUserProfilePicture()
        }
        
        // Configure the cell...

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let cell = tableView.cellForRow(at: indexPath) {
            if members.contains(results[indexPath.row]){
                cell.accessoryType = .none
                if let index = members.firstIndex(of: results[indexPath.row]){
                    
                    if let index2 = channel.members.firstIndex(of: members[index].uid ?? ""){
                    channel.metaData?.removeObject(forKey: members[index].uid ?? "")
                    channel.members.remove(at: index2)
                    }
                    
                    for token in results[indexPath.row].tokens{
                        if let index3 = channel.tokens.firstIndex(of: token){
                            channel.tokens.remove(at: index3)
                        }
                    }
                members.remove(at: index)
                }
            }else{
                if members.count < 30{
            cell.accessoryType = .checkmark
                members.append(results[indexPath.row])
                }else{
                    showError(msg: "Max 30 members allowed")
                }
            }
         updateMembersText()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 45
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return getHeaderView(with: "Select up to 30 members including yourself", tableView: tableView)
    }
    
    
}


extension CreateGroupViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            if let newImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
                self.presentCropViewController(image: newImage)
            }
        }
    }
}

extension CreateGroupViewController : CropViewControllerDelegate{
    func presentCropViewController(image : UIImage) {
        let cropViewController = CropViewController(croppingStyle: .circular, image: image)
      cropViewController.delegate = self
        self.present(cropViewController, animated: true, completion: nil)
    }

    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
            // 'image' is the newly cropped version of the original image
        self.image.setImage(image, for: .normal)
        FollowersHelper().uploadGroupPicture(data1: image.jpegData(compressionQuality: 0.2), imageName: UUID().uuidString, docID: channel.id ?? "")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadData"), object: nil)
        cropViewController.dismiss(animated: true, completion: nil)
        }
}
