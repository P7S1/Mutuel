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
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let discoverVC = storyboard.instantiateViewController(withIdentifier: "DiscoverViewController") as! DiscoverViewController
        let homeViewController = UINavigationController(rootViewController: discoverVC)
        homeViewController.tabBarItem = UITabBarItem(title: " ", image: UIImage(systemName: "house.fill"), tag: 1)
        
        let messagesVC = storyboard.instantiateViewController(withIdentifier: "ChannelsViewController") as! ChannelsViewController
        let secondViewController = UINavigationController(rootViewController: messagesVC)
        secondViewController.tabBarItem = UITabBarItem(title: " ", image: UIImage(systemName: "message.fill"), tag: 2)
        let actionViewController = storyboard.instantiateViewController(withIdentifier: "CameraVC") as! CameraVC

        actionViewController.tabBarItem = UITabBarItem(title: " ", image: UIImage(systemName: "plus.circle.fill"), tag: 3)
        
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
