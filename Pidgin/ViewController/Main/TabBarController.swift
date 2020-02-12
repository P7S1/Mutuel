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
        self.tabBar.shadowImage = UIImage()
        self.tabBar.backgroundColor = .none
        self.tabBar.barTintColor = .none
        self.tabBar.itemPositioning = .centered
        let config = UIImage.SymbolConfiguration(pointSize: 21, weight: .medium)
        let config2 = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let discoverVC = storyboard.instantiateViewController(withIdentifier: "DiscoverViewController") as! DiscoverViewController
        let homeViewController = UINavigationController(rootViewController: discoverVC)
        let discoverTab = UITabBarItem(title: " ", image: UIImage(systemName: "globe", withConfiguration: config2), tag: 1)
        discoverTab.setTitleTextAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 11, weight: .medium)], for: .normal)
        discoverTab.imageInsets = UIEdgeInsets(top: 8, left: 0, bottom: 00, right: 0)
        homeViewController.tabBarItem = discoverTab

        
        let messagesVC = storyboard.instantiateViewController(withIdentifier: "ChannelsViewController") as! ChannelsViewController
        let secondViewController = UINavigationController(rootViewController: messagesVC)
        let image = UIImage(systemName: "ellipses.bubble", withConfiguration: config2)
        
        image?.withTintColor(.systemPink, renderingMode: .alwaysOriginal)
        let messagesTab = UITabBarItem(title: " ", image: image, tag: 2)
        messagesTab.setTitleTextAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 11, weight: .medium)], for: .normal)
        messagesTab.imageInsets = UIEdgeInsets(top: 8, left: 0, bottom: -8, right: 0)
        secondViewController.tabBarItem = messagesTab
        
        
        let cameraImage =  UIImage(systemName: "circle", withConfiguration: config)?.withTintColor(.systemPink, renderingMode: .alwaysOriginal)
        let actionViewController = storyboard.instantiateViewController(withIdentifier: "CameraVC") as! CameraVC
        let cameraTab = UITabBarItem(title: nil, image: cameraImage, tag: 3)
        cameraTab.imageInsets = UIEdgeInsets(top: 8, left: 0, bottom: -8, right: 0)
        actionViewController.tabBarItem = cameraTab
    
        viewControllers = [homeViewController, actionViewController, secondViewController]
        
        NotificationCenter.default.addObserver(self,
        selector: #selector(applicationWillEnterBackground),
        name: UIApplication.willResignActiveNotification,
        object: nil)
        super.viewDidLoad()
    }
    
    @objc func applicationWillEnterBackground(){
        if self.tabBar.isHidden{
        changeTabBar(hidden: false
            , animated: true)
        }
    }
    
    func changeTabBar(hidden:Bool, animated: Bool){
        if tabBar.isHidden == hidden{ return }
        let frame = tabBar.frame
        print(frame.size.height)
        let offset = hidden ? frame.size.height : -frame.size.height
        let duration:TimeInterval = (animated ? 0.2 : 0.0)
        tabBar.isHidden = false

        UIView.animate(withDuration: duration, animations: {
            self.tabBar.frame = frame.offsetBy(dx: 0, dy: offset)
        }, completion: { (true) in
            self.tabBar.isHidden = hidden
        })
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
