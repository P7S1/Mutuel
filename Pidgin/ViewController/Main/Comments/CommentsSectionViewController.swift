//
//  CommentsSectionViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 1/25/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import CarbonKit

class CommentsSectionViewController: UIViewController, UIScrollViewDelegate, CarbonTabSwipeNavigationDelegate {
    
    
    var latestCommentsVC : CommentsViewController!
    
    var topCommentsVC : CommentsViewController!
    
    var post : Post!
    
    var commentCount = 0
    


    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Comments"
        self.view.backgroundColor = .systemBackground
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
        let vc1 = storyboard.instantiateViewController(withIdentifier: "CommentsViewController") as! CommentsViewController
        vc1.commentCount = commentCount
        latestCommentsVC = vc1
        
        vc1.commentsDelegate = self
        vc1.post = self.post
        let vc2 = storyboard.instantiateViewController(withIdentifier: "CommentsViewController") as! CommentsViewController
        
        topCommentsVC = vc2
        vc2.post = self.post
        vc2.commentsDelegate = self
        vc2.commentCount = commentCount
        topCommentsVC.originalQuery = db.collection("users").document(post.originalCreatorID).collection("posts").document(post.originalPostID).collection("comments").order(by: "likesCount")
        
        let items = ["Top", "Latest"]
        let carbonTabSwipeNavigation = CarbonSwipe(items: items, delegate: self)
        carbonTabSwipeNavigation.configure(items: items, vc: self)
        // Do any additional setup after loading the view.
    }
    
    
    func carbonTabSwipeNavigation(_ carbonTabSwipeNavigation: CarbonTabSwipeNavigation, viewControllerAt index: UInt) -> UIViewController {
        if index == 0{
         return topCommentsVC
        }else{
         return latestCommentsVC
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

extension CommentsSectionViewController : ExploreViewControllerDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
      
    }
    func collectionViewScrolled(_ scrollView: UIScrollView) {
        self.scrollViewDidScroll(scrollView)
    }
    
    
}


