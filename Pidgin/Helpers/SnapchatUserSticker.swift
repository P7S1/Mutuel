//
//  SnapchatUserSticker.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 4/13/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit

class SnapchatUserSticker: UIView {

    @IBOutlet weak var mutuelIcon: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "SnapchatUserSticker", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }

}
