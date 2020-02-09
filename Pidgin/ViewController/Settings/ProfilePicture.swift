//
//  ProfilePicture.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 1/15/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit

class ProfilePicture: UIView {
    
    var imageView : UIImageView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        DispatchQueue.main.async {
            self.imageView.kf.setImage(with: URL(string: User.shared.profileURL ?? ""), placeholder: FollowersHelper().getUserProfilePicture())
        }
        imageView.layer.cornerRadius = 50
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        self.addSubview(imageView)
        
        let widthConstraint = NSLayoutConstraint(item: imageView as Any, attribute: .width, relatedBy: .equal,
                                                 toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 100)

        let heightConstraint = NSLayoutConstraint(item: imageView as Any, attribute: .height, relatedBy: .equal,
                                                  toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 100)

        let xConstraint = NSLayoutConstraint(item: imageView as Any, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)

        let yConstraint = NSLayoutConstraint(item: imageView as Any, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)

        NSLayoutConstraint.activate([widthConstraint, heightConstraint, xConstraint, yConstraint])

        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
