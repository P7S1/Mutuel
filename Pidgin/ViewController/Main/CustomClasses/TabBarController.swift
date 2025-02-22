//
//  TabBarController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 10/8/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import Hero
import AwesomeSpotlightView
class TabBarController: UITabBarController, UITabBarControllerDelegate{

    let gradientlayer = CAGradientLayer()
    
    override func viewDidLoad() {
        self.delegate = self
        self.tabBar.isTranslucent = true
        self.tabBar.backgroundColor = .none
        self.tabBar.barTintColor = .systemBackground
        self.tabBar.unselectedItemTintColor = .label
        self.tabBar.itemPositioning = .centered
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let config2 = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let storyboard2 = UIStoryboard(name: "Discover", bundle: nil)
        let discoverVC = storyboard.instantiateViewController(withIdentifier: "DiscoverViewController") as! DiscoverViewController
        let homeViewController = UINavigationController(rootViewController: discoverVC)
        

    
        let discoverTab = UITabBarItem(title: nil, image: UIImage(systemName: "house", withConfiguration: config2), tag: 1)
        discoverTab.setTitleTextAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 11, weight: .medium)], for: .normal)
        homeViewController.tabBarItem = discoverTab
        
        let challengeVC = UINavigationController(rootViewController: storyboard2.instantiateViewController(withIdentifier: "ChallengesViewController") as! ChallengesViewController)
        let challengeTab = UITabBarItem(title: nil, image: UIImage(systemName: "rosette", withConfiguration: config2), tag: 1)
        challengeTab.setTitleTextAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 11, weight: .medium)], for: .normal)
        challengeVC.tabBarItem = challengeTab

        
        let messagesVC = storyboard.instantiateViewController(withIdentifier: "ChannelsViewController") as! ChannelsViewController
        let secondViewController = UINavigationController(rootViewController: messagesVC)
     
        let image = UIImage(systemName: "ellipses.bubble", withConfiguration: config2)
        
        //image?.withTintColor(.systemPink, renderingMode: .alwaysOriginal)
        let messagesTab = UITabBarItem(title: nil, image: image, tag: 2)
        messagesTab.setTitleTextAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 11, weight: .medium)], for: .normal)
        secondViewController.tabBarItem = messagesTab
        
        
        let cameraImage =  UIImage(systemName: "plus.app", withConfiguration: config)
        let actionViewController = UploadViewController()
        let cameraTab = UITabBarItem(title: nil, image: cameraImage, tag: 3)
        cameraTab.imageInsets = UIEdgeInsets(top: -5, left: 0, bottom: 0, right: 0)
        actionViewController.tabBarItem = cameraTab
        
        let activityVC = UINavigationController(rootViewController: storyboard2.instantiateViewController(withIdentifier: "ActivityViewController") as! ActivityViewController)
        let activityTab = UITabBarItem(title: nil, image: UIImage(systemName: "bolt", withConfiguration: config2), tag: 1)
        activityTab.setTitleTextAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 11, weight: .medium)], for: .normal)
        activityVC.tabBarItem = activityTab
 
        viewControllers = [homeViewController,challengeVC, actionViewController, activityVC, secondViewController]
        
        
        if firstLaunch{
        showSpotlightView()
        }
    }
    
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {

        if viewController.isKind(of: UploadViewController.self) {
            
            launchUploadVCIfPossible(challenge: nil, day: nil, isChallenge: false)
            
            return false
        }

        return true
    }
    
    func showSpotlightView(){
        let middle = self.view.frame.width/2
        let window = UIApplication.shared.keyWindow
        let topPadding = window?.safeAreaInsets.top ?? 0
        let rect = CGRect(x: middle-25, y: self.view.frame.height+8-50-topPadding, width: 50, height: 50)
        
        let spotlight = AwesomeSpotlight(withRect: rect, shape: .circle, text: "Tap the plus to post photos, videos, gifs, or use AR filters", isAllowPassTouchesThroughSpotlight: true)
        
        let spotlightView = AwesomeSpotlightView(frame: view.frame, spotlight: [spotlight])
        spotlightView.cutoutRadius = 8
        view.addSubview(spotlightView)
        spotlightView.start()
    }
}
    
    
    
    



