//
//  RelationshipViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/1/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import CarbonKit
class RelationshipViewController: UIViewController, CarbonTabSwipeNavigationDelegate {
    
    var user : Account!
    
    var followingVC : FollowersTableViewController!
    
    var followersVC : FollowersTableViewController!
    
    var selectedIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .systemBackground
        
        navigationItem.title = user.name
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        followingVC = storyboard.instantiateViewController(withIdentifier: "FollowersTableViewController") as? FollowersTableViewController
        followingVC.user = user
        followingVC.type = "following"
        
        followersVC = storyboard.instantiateViewController(withIdentifier: "FollowersTableViewController") as? FollowersTableViewController
        followersVC.user = user
        followersVC.type = "followers"
        
        let items = ["Followers", "Following"]
        let carbonTabSwipeNavigation = CarbonSwipe(items: items, delegate: self)
        carbonTabSwipeNavigation.configure(items: items, vc: self)
        carbonTabSwipeNavigation.setCurrentTabIndex(UInt(selectedIndex), withAnimation: false)
        
        // Do any additional setup after loading the view.
    }
    
    func carbonTabSwipeNavigation(_ carbonTabSwipeNavigation: CarbonTabSwipeNavigation, viewControllerAt index: UInt) -> UIViewController {
        if index == 0{
         return followersVC
        }else{
         return followingVC
        }
        // return viewController at index
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
