//
//  ActivityItemsViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/7/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import CarbonKit
import FirebaseFirestore
class ActivityItemsViewController: UIViewController, CarbonTabSwipeNavigationDelegate {
    
    var allItemsVC : ActivityViewController!
    
    var postsVC : ActivityViewController!
    
    var followersVC : ActivityViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        
        self.navigationItem.title = "Activity"
        
        self.view.backgroundColor = .systemBackground
        
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
        
        guard let userID = User.shared.uid else {
            navigationController?.popViewController(animated: true)
            return
        }
        
        allItemsVC = storyboard.instantiateViewController(withIdentifier: "ActivityViewController") as? ActivityViewController
        allItemsVC.originalQuery = db.collection("users").document(userID).collection("activity").limit(to: 16).order(by: "date", descending: true)
        
        followersVC = storyboard.instantiateViewController(withIdentifier: "ActivityViewController") as? ActivityViewController
        
        followersVC.originalQuery = db.collection("users").document(userID).collection("activity").whereField("type", in: ["follower"]).limit(to: 16).order(by: "date", descending: true)
        
        postsVC = storyboard.instantiateViewController(withIdentifier: "ActivityViewController") as? ActivityViewController
        postsVC.originalQuery = db.collection("users").document(userID).collection("activity").whereField("type", in: ["comment","commentReply","post"]).limit(to: 16).order(by: "date", descending: true)
        
        
        let items = ["All","Followers", "Posts"]
        let carbonTabSwipeNavigation = CarbonSwipe(items: items, delegate: self)
        carbonTabSwipeNavigation.delegate = self
        carbonTabSwipeNavigation.configure(items: items, vc: self)
        

        // Do any additional setup after loading the view.
    }
    
    func carbonTabSwipeNavigation(_ carbonTabSwipeNavigation: CarbonTabSwipeNavigation, viewControllerAt index: UInt) -> UIViewController {
        if index == 0{
          return allItemsVC
        }else if index == 1{
           return followersVC
        }else{
            return postsVC
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
