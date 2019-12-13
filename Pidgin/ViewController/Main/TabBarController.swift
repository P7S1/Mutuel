//
//  TabBarController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 10/8/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
var homeViewController: DiscoverViewController!
var secondViewController: ChannelsViewController!
var actionViewController: CameraVC!

class TabBarController: UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        self.delegate = self
        
    
        
        let discoverVC = self.storyboard?.instantiateViewController(withIdentifier: "DiscoverViewController") as! DiscoverViewController
        
        let homeViewController = UINavigationController(rootViewController: discoverVC)
        let item = UITabBarItem()
        if #available(iOS 13.0, *) {
            item.image = UIImage(systemName: "house.fill")
        }
        homeViewController.tabBarItem = item
        
        let messagesVC = self.storyboard?.instantiateViewController(withIdentifier: "ChannelsViewController") as! ChannelsViewController
        let secondViewController = UINavigationController(rootViewController: messagesVC)
        let item2 = UITabBarItem()
        if #available(iOS 13.0, *) {
            item2.image = UIImage(systemName: "text.bubble.fill")
        }
        secondViewController.tabBarItem = item2
        
        let actionViewController = self.storyboard?.instantiateViewController(withIdentifier: "CameraVC") as! CameraVC?
        let item3 = UITabBarItem()
        if #available(iOS 13.0, *) {
            item3.image = UIImage(systemName: "plus.square.fill")
        }
        item3.badgeColor = .systemPink
        actionViewController?.tabBarItem = item3
        
        viewControllers = [homeViewController, actionViewController, secondViewController] as? [UIViewController]
            //remove titles
     /*       for tabBarItem in tabBar.items! {
                tabBarItem.title = ""
                tabBarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
            } */
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {

        
        if viewController.isKind(of: CameraVC.self) {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "CameraVC") as! CameraVC?
            vc?.modalPresentationStyle = .fullScreen
            self.present(vc!, animated: true, completion: nil)
            return false
        }

        return true
    }
    
    func getSizedImage(imageName : String) -> UIImage{
           let image = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30)).image { _ in
                    UIImage(named: imageName)
        
                }
            return image
    }
        
}
