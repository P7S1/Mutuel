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
        self.tabBar.isTranslucent = false
        self.tabBar.shadowImage = UIImage()
        self.tabBar.backgroundColor = .none
        self.tabBar.barTintColor = .none
        self.tabBar.itemPositioning = .centered
        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .bold)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let discoverVC = storyboard.instantiateViewController(withIdentifier: "DiscoverViewController") as! DiscoverViewController
        let homeViewController = UINavigationController(rootViewController: discoverVC)
        let discoverTab = UITabBarItem(title: " ", image: UIImage(systemName: "house.fill", withConfiguration: config), tag: 1)
        discoverTab.imageInsets = UIEdgeInsets(top: 9, left: 0, bottom: -9, right: 0)
        homeViewController.tabBarItem = discoverTab
        
        let messagesVC = storyboard.instantiateViewController(withIdentifier: "ChannelsViewController") as! ChannelsViewController
        let secondViewController = UINavigationController(rootViewController: messagesVC)
        let messagesTab = UITabBarItem(title: " ", image: UIImage(systemName: "ellipses.bubble.fill", withConfiguration: config), tag: 2)
        messagesTab.imageInsets = UIEdgeInsets(top: 9, left: 0, bottom: -9, right: 0)
        secondViewController.tabBarItem = messagesTab
        
        
        let actionViewController = storyboard.instantiateViewController(withIdentifier: "CameraVC") as! CameraVC
        let cameraTab = UITabBarItem(title: " ", image: UIImage(systemName: "circle", withConfiguration: config), tag: 3)
        cameraTab.imageInsets = UIEdgeInsets(top: 9, left: 0, bottom: -9, right: 0)
        actionViewController.tabBarItem = cameraTab
        
        viewControllers = [homeViewController, actionViewController, secondViewController]
        super.viewDidLoad()
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {

        if viewController.isKind(of: CameraVC.self) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "CameraVC") as! CameraVC
            vc.isHeroEnabled = true
            vc.hero.modalAnimationType = .selectBy(presenting:.zoom, dismissing:.zoomOut)
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true, completion: nil)
            return false
        }

        return true
    }

}
