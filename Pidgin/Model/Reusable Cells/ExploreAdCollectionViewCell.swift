//
//  ExploreAdCollectionViewCell.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/26/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import GoogleMobileAds
class ExploreAdCollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var adView: GADUnifiedNativeAdView!
    
    
    @IBOutlet weak var adBlurView: UIVisualEffectView!
    
    func setUpView(){
        adView.mediaView?.layer.masksToBounds = true
        adView.mediaView?.layer.cornerRadius = 10
        
        adBlurView.layer.masksToBounds = true
        adBlurView.layer.cornerRadius = adBlurView.frame.height/2
    }
    
}
