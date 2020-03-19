//
//  DiscoverViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 10/8/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import FirebaseAuth
import FirebaseFirestore
import CollectionViewWaterfallLayout
import CarbonKit
class DiscoverViewController: HomeViewController, ExploreViewControllerDelegate, UICollectionViewDelegate, CarbonTabSwipeNavigationDelegate {

    
    var exploreVC : ExploreViewController!
    
    var followingVC : FollowingViewController!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(presentNotification), name: NSNotification.Name(rawValue: "presentNotification"), object: nil)
        setupUI()
        self.configureNavItem(name: "Trending")
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
        exploreVC = storyboard.instantiateViewController(withIdentifier: "ExploreViewController") as? ExploreViewController
        exploreVC.query = db.collectionGroup("posts").whereField("isRepost", isEqualTo: false).whereField("isPrivate", isEqualTo: false).order(by: "publishDate", descending: true).limit(to: 20)
        exploreVC.exploreDelegate = self
        
        followingVC  = storyboard.instantiateViewController(withIdentifier: "FollowingViewController") as? FollowingViewController
        followingVC.followingDelegate = self
        navigationItem.largeTitleDisplayMode = .never
        
        let items = ["Trending", "Following"]
        let carbonTabSwipeNavigation = CarbonSwipe(items: items, delegate: self)
        carbonTabSwipeNavigation.configure(items: items, vc: self)
    
        
        //Camera
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                //access granted
            } else {

            }
        }
        //Microphone
        AVCaptureDevice.requestAccess(for: AVMediaType.audio) { (response) in
            if response{
                
            } else{
                
            }
        }
        //Photos
        let photos = PHPhotoLibrary.authorizationStatus()
        if photos == .notDetermined {
            PHPhotoLibrary.requestAuthorization({status in
                if status == .authorized{
                
                } else {}
            })
        }
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    func collectionViewScrolled(_ scrollView: UIScrollView) {
        self.scrollViewDidScroll(scrollView)
        
    }
    
    func carbonTabSwipeNavigation(_ carbonTabSwipeNavigation: CarbonTabSwipeNavigation, viewControllerAt index: UInt) -> UIViewController {
        if index == 0{
         return exploreVC
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

