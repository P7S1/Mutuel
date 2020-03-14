//
//  ProfileViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 11/10/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseStorage
import Kingfisher
import Lightbox
import SkeletonView
protocol ProfileDelegate {
    func handleMoreButtonPressed(_ sender: Any)
    func handleProfilePictureTapped()
    func handleFollowersTapped()
    func didPressFollowButton(_ sender: Any)
}
class ProfileViewController: UIViewController{
    
    @IBOutlet weak var followingStackView: UIStackView!
    @IBOutlet weak var followersStackView: UIStackView!
    
    var profileDelegate : ProfileDelegate?
    
    var user : Account?
    
    @IBOutlet weak var profile: UIImageView!
    
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var displayName: UILabel!
    
    @IBOutlet weak var following: UILabel!
    @IBOutlet weak var followers: UILabel!
    
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var username: UILabel!
    
    
    
    var isCurrentUser = false
    
    
    var userFollows = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        NotificationCenter.default.addObserver(self, selector: #selector(presentNotification), name: NSNotification.Name(rawValue: "presentNotification"), object: nil)
        navigationItem.largeTitleDisplayMode = .never
        
        if user?.uid == User.shared.uid{
            isCurrentUser = true
        }
        
        followersStackView.isUserInteractionEnabled = true
        followingStackView.isUserInteractionEnabled = true
        profile.isUserInteractionEnabled = true
        
        
        let followersGesture = UITapGestureRecognizer(target: self, action: #selector(handleFollowersTapped))
        followersStackView.addGestureRecognizer(followersGesture)
        
        let followingGesture = UITapGestureRecognizer(target: self, action: #selector(handleFollowingTapped))
        followingStackView.addGestureRecognizer(followingGesture)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleProfilePictureTapped))
        profile.addGestureRecognizer(gesture)
        
        
        //set profile url
        if let string = user?.profileURL{
            DispatchQueue.main.async {
                if let url = URL(string: string){
                    self.profile.isSkeletonable = true
                    let gradient = SkeletonGradient(baseColor: UIColor.secondarySystemBackground)
                    self.profile.showAnimatedGradientSkeleton(usingGradient: gradient)
                    self.profile.kf.setImage(with: URL(string: url.absoluteString)) { (result) in
                        self.profile.stopSkeletonAnimation()
                    self.profile.hideSkeleton(reloadDataAfter: false, transition: .crossDissolve(0.2))
                    }
                    self.profile.heroID = url.absoluteString
                }else{
                    print("error url was nil")
                    self.profile.image = UIImage(named:"icons8-male-user-96")
                }
            }
        }
        self.profile.layer.cornerRadius = self.profile.bounds.height / 2
        self.profile.clipsToBounds = true
        followers.text = "\(user?.followersCount ?? 0)"
        following.text = "\(user?.followingCount ?? 0)"
    
        followButton.isEnabled = false
        followButton.setTitle("", for: .normal)
        followButton.backgroundColor = .systemGray6
        followButton.roundCorners()
        
        user?.printClass()
        
        if !isCurrentUser{
            guard let follower = User.shared.uid else {
                self.dismiss(animated: true, completion: nil)
                return }
            guard let followed = user?.uid else {
                self.dismiss(animated: true, completion: nil)
                return }
            let docRef = db.collection("users").document(follower).collection("relationships").document("\(follower)_\(followed)")
            docRef.getDocument { (document, error) in
                if let document = document {
                    if document.exists{
                        
                        let relationship = Relationship(document: document)
                        if relationship.isApproved ?? false{
                            self.setFollowingState()
                        }
                    } else {

                        self.setNotFollowingState()

                    }
                }
                if let err = error{
                    print(err.localizedDescription)
                }
                 self.followButton.isEnabled = true
            }

            
           
        
        }else{
            followButton.setTitle("ACTIVITY", for: .normal)
            followButton.setTitleColor(.systemGreen, for: .normal)
            followButton.backgroundColor = .systemGray6
            followButton.isEnabled = true
        }
        
        
        self.username.text = "@\(user?.username ?? "Unknown")"
        self.navigationItem.title = ""
        
        displayName.text = user?.name ?? "Unknown"
        
        moreButton.backgroundColor = .systemGray6
        moreButton.tintColor = .label
        moreButton.roundCorners()

        // Do any additional setup after loading the view.
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
    
    @IBAction func handleMoreButtonPressed(_ sender: Any) {
        let alertController = UIAlertController(title: user?.name, message:"@\(user?.username ?? "Unknown")" , preferredStyle: .actionSheet)
        if self.user?.uid != User.shared.uid{
            alertController.addAction(UIAlertAction(title: "Block \(user?.name ?? "")", style: .default, handler: { (action) in
                print("blocking user")
                let alert = UIAlertController(title: "Block \(self.user?.name ?? "")", message: "Are you sure you want to block \(self.user?.name ?? "")? This will make you both unfollow each other.", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Block", style: .destructive, handler: { (action) in
                
                    
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                    print("user cancelled")
                }))
                
                self.present(alert, animated: true, completion: nil)
            }))
    }
        
            var text = "Send Message"
            if self.user?.uid == User.shared.uid {
                text = "Settings"
            }
            
            alertController.addAction(UIAlertAction(title: text, style: .default, handler: { (action) in
                self.settingsButtonPressed()
            }))
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                print("cancelled")
            }))
        

            self.present(alertController, animated: true, completion: nil)
    }
    
     func settingsButtonPressed(){
      if isCurrentUser{
            let storyboard = UIStoryboard(name: "Settings", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "SettingsTableViewController") as! SettingsTableViewController
        navigationController?.pushViewController(vc, animated: true)
        }else{
        if let id1 = User.shared.uid, let id2 = user?.uid{
        let docRef = db.collection("channels").document(FollowersHelper().getChannelID(id1: id1, id2: id2))
            docRef.getDocument { (snapshot, error) in
                if error == nil{
                let channel = Channel(document: snapshot!)
                let vc = ChatViewController()
                vc.channel = channel
                self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
            
        }
    }
    
    @objc func handleProfilePictureTapped(){
        print("profile picture tappped")
        if let string = user?.profileURL, let url = URL(string : string){
            let images : [LightboxImage] = [LightboxImage(imageURL: url)]
            self.presentLightBoxController(images: images, goToIndex: nil)
        }
        
    }
    
    @objc func handleFollowingTapped(){
        print("handleFollowingTapped")
        let vc = RelationshipViewController()
        vc.user = user
        vc.selectedIndex = 1
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func handleFollowersTapped(){
        print("handleFollowersTapped")
        let vc = RelationshipViewController()
        vc.user = user
        vc.selectedIndex = 0
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func setFollowingState(){
        followButton.setTitle("UNFOLLOW", for: .normal)
        followButton.setTitleColor(.systemPink, for: .normal)
        followButton.backgroundColor = .systemGray6
        self.userFollows = true
    }
    
    func setNotFollowingState(){
        followButton.setTitle("FOLLOW", for: .normal)
        followButton.setTitleColor(.white, for: .normal)
        followButton.backgroundColor = .systemBlue
        self.userFollows = false
    }
    
    @IBAction func didPressFollowButton(_ sender: Any) {
        if !isCurrentUser{
            followButton.isEnabled = false
        if let followee = self.user{
            if userFollows{
                FollowersHelper().unFollow(followeeUser: followee) { (success) in
                    if success{
                        self.setNotFollowingState()
                        self.followButton.isEnabled = true
                        DispatchQueue.main.async {
                            self.user?.followersCount = (self.user?.followersCount ?? 0) - 1
                            self.followers.text = "\((self.user?.followersCount ?? 0) )"
                        }
                    }
                }
            }else{
                FollowersHelper().follow(followeeUser: followee) { (success) in
                    if success{
                        self.setFollowingState()
                        self.followButton.isEnabled = true
                        DispatchQueue.main.async {
                            self.user?.followersCount = (self.user?.followersCount ?? 0) + 1
                            self.followers.text = "\((self.user?.followersCount ?? 0)  )"
                        }
                    }
                }
            }
        }else{
            print("failed to follow user")
        }
        }else{
            self.followButton.isEnabled = true
            let vc = ActivityItemsViewController()
            self.navigationController?.pushViewController(vc, animated: true)
            print("did press avtivity")
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
