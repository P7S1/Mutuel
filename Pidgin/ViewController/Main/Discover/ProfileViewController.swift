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
class ProfileViewController: UIViewController{
    
    @IBOutlet weak var followingStackView: UIStackView!
    @IBOutlet weak var followersStackView: UIStackView!
    
    
    
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
        
        let settings = UIButton.init(type: .system)
        if isCurrentUser{
            settings.setImage(UIImage.init(named: "icons8-settings-100")?.withRenderingMode(.alwaysTemplate), for: UIControl.State.normal)
        }else{
            settings.setImage(UIImage(systemName: "square.and.pencil")?.withRenderingMode(.alwaysTemplate), for: .normal)
        }
        settings.addTarget(self, action:#selector(settingsBarButtonPressed), for:.touchUpInside)
        settings.widthAnchor.constraint(equalToConstant: 25).isActive = true
        settings.heightAnchor.constraint(equalToConstant: 25).isActive = true
        let settingsButton = UIBarButtonItem.init(customView: settings)
        navigationItem.rightBarButtonItems = [settingsButton]
        //set profile url
        if let string = user?.profileURL{
            DispatchQueue.main.async {
                if let url = URL(string: string){
                    self.profile.kf.setImage(with: url,placeholder: FollowersHelper().getUserProfilePicture())
                }else{
                    print("error url was nil")
                    self.profile.image = UIImage(named:"icons8-male-user-96")
                }
            }
        }
        self.profile.layer.cornerRadius = self.profile.bounds.height / 2
        self.profile.clipsToBounds = true
        followers.text = "\(user?.followersCount ?? 0)"
        following.text = "\(user?.following.count ?? 0)"
    
        followButton.isEnabled = false
        followButton.backgroundColor = .systemGray6
        followButton.roundCorners()
        
        user?.printClass()
        
        if !isCurrentUser{
            
            if User.shared.following.contains(user?.uid ?? ""){
                print("user follows")
                self.setFollowingState()
            }else{
                self.setNotFollowingState()
            }
            
            self.followButton.isEnabled = true
        
        }else{
            followButton.setTitle("ACTIVITY", for: .normal)
            followButton.setTitleColor(.systemPink, for: .normal)
            followButton.backgroundColor = .systemGray6
            followButton.isEnabled = true
        }
        
        
        self.username.text = "@\(user?.username ?? "Unknown")"
        self.navigationItem.title = ""
        
        displayName.text = user?.name ?? "Unknown"
        

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
            
            alertController.addAction(UIAlertAction(title: "Block \(user?.name ?? "")", style: .default, handler: { (action) in
                print("blocking user")
                let alert = UIAlertController(title: "Block \(self.user?.name ?? "")", message: "Are you sure you want to block \(self.user?.name ?? "")? This will make you both unfollow each other.", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Block", style: .destructive, handler: { (action) in
                
                    
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                    print("user cancelled")
                }))
                alert.view.tintColor = .systemPink
                self.present(alert, animated: true, completion: nil)
            }))
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                print("cancelled")
            }))
            alertController.view.tintColor = .systemPink
            self.present(alertController, animated: true, completion: nil)
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
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "FollowersTableViewController") as! FollowersTableViewController
        
        vc.user = user
        
        vc.type = "following"
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func handleFollowersTapped(){
        print("handleFollowersTapped")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "FollowersTableViewController") as! FollowersTableViewController
        
   
        vc.user = user
        
        vc.type = "followers"
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func setFollowingState(){
        followButton.setTitle("UNFOLLOW", for: .normal)
        followButton.setTitleColor(.systemPink, for: .normal)
        followButton.backgroundColor = .systemGray6
        self.userFollows = true
    }
    
    func setNotFollowingState(){
        followButton.tintColor = .systemPink
        followButton.setTitle("FOLLOW", for: .normal)
        followButton.setTitleColor(.white, for: .normal)
        followButton.backgroundColor = .systemPink
        self.userFollows = false
    }
    
    @IBAction func didPressFollowButton(_ sender: Any) {
        if !isCurrentUser{
        if let me = User.shared.uid, let followee = self.user?.uid{
            if userFollows{
                FollowersHelper().unFollow(follower: me, followee: followee)
                setNotFollowingState()
            }else{
                FollowersHelper().follow(follower: me, followee: followee, tokens: self.user?.tokens ?? [String]())
            setFollowingState()
            }
        }else{
            print("failed to follow user")
        }
        }else{
            print("did press avtivity")
        }
    }
    
    @objc func settingsBarButtonPressed(){
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
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
