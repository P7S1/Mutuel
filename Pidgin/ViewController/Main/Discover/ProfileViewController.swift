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
class ProfileViewController: UIViewController {
    
    @IBOutlet weak var followingStackView: UIStackView!
    @IBOutlet weak var followersStackView: UIStackView!
    
    
    
    var user : Account?
    
    @IBOutlet weak var profile: UIImageView!
    
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var displayName: UILabel!
    
    @IBOutlet weak var following: UILabel!
    @IBOutlet weak var followers: UILabel!
    
    @IBOutlet weak var settingsButton: UIButton!
    
    
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

        let followersGesture = UITapGestureRecognizer(target: self, action: #selector(handleFollowersTapped))
        followersStackView.addGestureRecognizer(followersGesture)
        
        let followingGesture = UITapGestureRecognizer(target: self, action: #selector(handleFollowingTapped))
        followingStackView.addGestureRecognizer(followingGesture)
        
        let settings = UIButton.init(type: .system)
        if isCurrentUser{
            settings.setImage(UIImage.init(named: "icons8-settings-100")?.withRenderingMode(.alwaysTemplate), for: UIControl.State.normal)
        }else{
            settings.setImage(UIImage(systemName: "ellipsis.circle.fill")?.withRenderingMode(.alwaysTemplate), for: .normal)
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
        
        user?.printClass()
        
        if !isCurrentUser{
            
            if User.shared.following.contains(user?.uid ?? ""){
                print("user follows")
                self.setFollowingState()
            }
            
            self.followButton.isEnabled = true
        
        }else{
            if #available(iOS 13.0, *) {
                self.followButton.backgroundColor = .systemGray6
            } else {
                self.followButton.backgroundColor = .clear
                // Fallback on earlier versions
            }
            followButton.setTitle("Activity", for: .normal)
            followButton.setTitleColor(.systemPink, for: .normal)
            followButton.isEnabled = true
        }
        
        
        
        
       self.navigationItem.title = "\(user?.username ?? "Unknown")"
        
        displayName.text = user?.name ?? "Unknown"
        
        followButton.roundCorners()
        

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
        self.followButton.setTitle("Unfollow", for: .normal)
        self.followButton.setTitleColor(.systemPink, for: .normal)
        if #available(iOS 13.0, *) {
            self.followButton.backgroundColor = .systemGray6
        } else {
            self.followButton.backgroundColor = .clear
            // Fallback on earlier versions
        }
        self.userFollows = true
    }
    
    func setNotFollowingState(){
        self.followButton.setTitle("Follow", for: .normal)
        self.followButton.setTitleColor(.white, for: .normal)
        self.followButton.backgroundColor = .systemPink
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
        let alertController = UIAlertController(title: user?.name, message:"@\(user?.username ?? "Unknown")" , preferredStyle: .actionSheet)
    
        alertController.addAction(UIAlertAction(title: "Send Message", style: .default, handler: { (action) in
            print("send message")
        }))
        
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

