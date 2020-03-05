//
//  TabBarController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 10/8/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import Hero

class TabBarController: UITabBarController, UITabBarControllerDelegate{
    
    let gradientlayer = CAGradientLayer()
    
    override func viewDidLoad() {
        self.delegate = self
        self.tabBar.isTranslucent = true
        self.tabBar.backgroundColor = .none
        self.tabBar.barTintColor = .systemBackground
        self.tabBar.itemPositioning = .centered
        let config = UIImage.SymbolConfiguration(pointSize: 21, weight: .medium)
        let config2 = UIImage.SymbolConfiguration(pointSize: 19, weight: .medium)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let discoverVC = storyboard.instantiateViewController(withIdentifier: "DiscoverViewController") as! DiscoverViewController
        let homeViewController = UINavigationController(rootViewController: discoverVC)
    
        let discoverTab = UITabBarItem(title: " ", image: UIImage(systemName: "globe", withConfiguration: config2), tag: 1)
        discoverTab.setTitleTextAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 11, weight: .medium)], for: .normal)
        homeViewController.tabBarItem = discoverTab

        
        let messagesVC = storyboard.instantiateViewController(withIdentifier: "ChannelsViewController") as! ChannelsViewController
        let secondViewController = UINavigationController(rootViewController: messagesVC)
     
        let image = UIImage(systemName: "ellipses.bubble", withConfiguration: config2)
        
        image?.withTintColor(.systemPink, renderingMode: .alwaysOriginal)
        let messagesTab = UITabBarItem(title: " ", image: image, tag: 2)
        messagesTab.setTitleTextAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 11, weight: .medium)], for: .normal)
        messagesTab.imageInsets = UIEdgeInsets(top: -8, left: -8, bottom: 000, right: 0)
        secondViewController.tabBarItem = messagesTab
        
        
        let cameraImage =  UIImage(systemName: "plus.app", withConfiguration: config)?.withTintColor(.systemPink, renderingMode: .alwaysOriginal)
        let actionViewController = UploadViewController()
        let cameraTab = UITabBarItem(title: nil, image: cameraImage, tag: 3)
        actionViewController.tabBarItem = cameraTab
 
        viewControllers = [homeViewController, actionViewController, secondViewController]
        

    }
    
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {

        if viewController.isKind(of: UploadViewController.self) {
            let vc = UploadViewController()
            self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
            return false
        }

        return true
    }

}
