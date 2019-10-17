//
//  TabBarController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 10/8/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
var homeViewController: DiscoverViewController!
var secondViewController: MessagesViewController!
var actionViewController: CameraVC!

class TabBarController: UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        self.delegate = self
        
        let discoverVC = self.storyboard?.instantiateViewController(withIdentifier: "DiscoverViewController") as! DiscoverViewController
        let homeViewController = UINavigationController(rootViewController: discoverVC)
        let item = UITabBarItem()
        item.image = getSizedImage(imageName: "icons8-home-50")
        homeViewController.tabBarItem = item
        
        let messagesVC = self.storyboard?.instantiateViewController(withIdentifier: "MessagesViewController") as! MessagesViewController
        let secondViewController = UINavigationController(rootViewController: messagesVC)
        let item2 = UITabBarItem()
        item2.image = getSizedImage(imageName: "icons8-topic-50")
        secondViewController.tabBarItem = item2
        
        let actionViewController = self.storyboard?.instantiateViewController(withIdentifier: "CameraVC") as! CameraVC?
        let item3 = UITabBarItem()
            item3.image = getSizedImage(imageName: "icons8-unsplash-50")
        actionViewController?.tabBarItem = item3
        
        viewControllers = [homeViewController, actionViewController, secondViewController] as? [UIViewController]
            
            var color = UIColor()
            if #available(iOS 13.0, *) {
                color = .secondaryLabel
            } else {
                color = .darkGray
                // Fallback on earlier versions
            }
            
            UINavigationBar.appearance().titleTextAttributes = [ NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.bold)
            ,NSAttributedString.Key.foregroundColor : color]
            
            UINavigationBar.appearance().isTranslucent = false
        
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
                UIImage(named: imageName)?.draw(in: CGRect(x: 0, y: 0, width: 30, height: 30))
    
            }
        return image
}
}
