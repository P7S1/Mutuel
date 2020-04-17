//
//  SnapchatSticker.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 4/13/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit

class SnapchatSticker: UIView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var username: UILabel!
    var post : Post?
    @IBOutlet weak var profilePictureView: UIImageView!
    @IBOutlet weak var caption: UILabel!
    @IBOutlet weak var playButton: UIImageView!
    
    @IBOutlet weak var mutuelIcon: UIImageView!
    
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "SnapchatSticker", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
    
}
