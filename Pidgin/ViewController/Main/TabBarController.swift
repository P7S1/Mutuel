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
        let config = UIImage.SymbolConfiguration(pointSize: 21, weight: .medium)
        let config2 = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let discoverVC = storyboard.instantiateViewController(withIdentifier: "DiscoverViewController") as! DiscoverViewController
        let homeViewController = UINavigationController(rootViewController: discoverVC)
        let discoverTab = UITabBarItem(title: "Discover", image: UIImage(systemName: "globe", withConfiguration: config2), tag: 1)
        homeViewController.tabBarItem = discoverTab
        
        let messagesVC = storyboard.instantiateViewController(withIdentifier: "ChannelsViewController") as! ChannelsViewController
        let secondViewController = UINavigationController(rootViewController: messagesVC)
        let image = UIImage(systemName: "ellipses.bubble", withConfiguration: config2)
        
        image?.withTintColor(.systemPink, renderingMode: .alwaysOriginal)
        let messagesTab = UITabBarItem(title: "Chat", image: image, tag: 2)
        secondViewController.tabBarItem = messagesTab
        
        
        let cameraImage =  UIImage(systemName: "circle", withConfiguration: config)?.withTintColor(.systemPink, renderingMode: .alwaysOriginal)
        let actionViewController = storyboard.instantiateViewController(withIdentifier: "CameraVC") as! CameraVC
        let cameraTab = UITabBarItem(title: nil, image: cameraImage, tag: 3)
        cameraTab.badgeColor = .systemPink
        cameraTab.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: -16, right: 0)
        cameraTab.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -16)
        actionViewController.tabBarItem = cameraTab
        actionViewController.tabBarItem.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -16)
        actionViewController.tabBarItem.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: -16, right: 0)
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
