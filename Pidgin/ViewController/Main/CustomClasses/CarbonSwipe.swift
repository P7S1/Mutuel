//
//  CarbonSwipe.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/1/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import CarbonKit

class CarbonSwipe : CarbonTabSwipeNavigation {
    
    func configure(items : [String], vc : UIViewController){
        self.insert(intoRootViewController: vc)
           self.setNormalColor(.secondaryLabel, font: UIFont(name: "AvenirNext-Bold", size: 17
           )!)
           self.setSelectedColor(.label, font: UIFont(name: "AvenirNext-Bold", size: 17
           )!)
           self.setIndicatorColor(.systemPink)
           self.setTabBarHeight(40)
           self.carbonSegmentedControl?.backgroundColor = .systemBackground
           self.toolbar.barTintColor = .systemBackground
           self.toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        
        
           for i in 0...items.count-1{
        self.carbonSegmentedControl?.setWidth((vc.view.frame.width/CGFloat(items.count)), forSegmentAt: i)
           }
        
        
        
    }

}

extension CarbonSwipe {
    
    func config(items : [String], vc : UIViewController){
        self.insert(intoRootViewController: vc,andTargetView: vc.view)
           self.setNormalColor(.secondaryLabel, font: UIFont(name: "AvenirNext-Bold", size: 17
           )!)
           self.setSelectedColor(.label, font: UIFont(name: "AvenirNext-Bold", size: 17
           )!)
           self.setIndicatorColor(.systemPink)
           self.setTabBarHeight(40)
           self.carbonSegmentedControl?.backgroundColor = .systemBackground
           self.toolbar.barTintColor = .systemBackground
           self.toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        
        
           for i in 0...items.count-1{
        self.carbonSegmentedControl?.setWidth((vc.view.frame.width/CGFloat(items.count)), forSegmentAt: i)
           }
        
        
        
    }
}
