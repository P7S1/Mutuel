//
//  FollowingCollectionViewCell.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 12/29/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
protocol cellDelegate {
    func didSelectUser()
}
class FollowingCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var containerView: UIView!
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    
    @IBOutlet weak var engagementStackView: UIStackView!
    
    @IBOutlet weak var caption: UILabel!
    
    @IBOutlet weak var repostsLabel: UILabel!
    
    
    @IBOutlet weak var commentsLabel: UILabel!
    

    @IBOutlet weak var gradientView: BackGradientView!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var profilePictureView: UIImageView!
    
    @IBOutlet weak var topView: UIView!
    
    
    var btnTapAction : (()->())?

    func setUpGestures(){
       let tap = UITapGestureRecognizer(target: self, action: #selector(btnTapped))
        topView.addGestureRecognizer(tap)
    }
    func addButtonShadows(){
        blurView.layer.cornerRadius = blurView.frame.height/2
        blurView.clipsToBounds = true
    }
    
    @objc func btnTapped() {
        print("Tapped!")

        // use our "call back" action to tell the controller the button was tapped
        btnTapAction?()
    }
}
