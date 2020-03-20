//
//  FollowingCollectionViewCell.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 12/29/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import Kingfisher
protocol cellDelegate {
    func didSelectUser()
}
class FollowingCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var containerView: UIView!
    
    
    @IBOutlet weak var imageView: AnimatedImageView!
    
    @IBOutlet weak var caption: UILabel!
    

    @IBOutlet weak var gradientView: BackGradientView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var profilePictureView: UIImageView!
    
    @IBOutlet weak var topView: UIView!
    
    @IBOutlet weak var playerContainerView: PlayerContainerView!
    
    @IBOutlet weak var height: NSLayoutConstraint!
    
    @IBOutlet weak var playButton: UIImageView!
    
    @IBOutlet weak var yAnchor: NSLayoutConstraint!
    
    
    
    @IBOutlet weak var moreButton: UIButton!
    
    @IBOutlet weak var challengeView: UIView!
    
    @IBOutlet weak var challengeText: UILabel!
    
    
    
    var btnTapAction : (()->())?
    
    var moreTapAction : (()->())?
    
    var challengeTapAction : (()->())?

    func setUpGestures(){
       let tap = UITapGestureRecognizer(target: self, action: #selector(btnTapped))
        topView.addGestureRecognizer(tap)
        
        let moreTapGesture = UITapGestureRecognizer(target: self, action: #selector(moreButtonTapped))
        moreButton.addGestureRecognizer(moreTapGesture)
        
        let challengeGesture = UITapGestureRecognizer(target: self, action: #selector(challengeTapped))
        challengeView.addGestureRecognizer(challengeGesture)
    } 
    func setUpPlayer(post : Post){
        playerContainerView.backgroundColor = .clear
        if post.isVideo{
            playerContainerView.play()
        }else{
            playerContainerView.isHidden = true
        }
    }
    
    @objc func moreButtonTapped(_ sender: Any) {
        print("more button tapped")
        moreTapAction?()
    }
    
    
    @objc func btnTapped() {
        print("Tapped!")

        // use our "call back" action to tell the controller the button was tapped
        btnTapAction?()
    }
    
    @objc func challengeTapped(){
        challengeTapAction?()
    }
    
}
