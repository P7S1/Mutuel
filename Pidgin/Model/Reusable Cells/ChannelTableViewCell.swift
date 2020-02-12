//
//  ChannelTableViewCell.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 10/28/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit

class ChannelTableViewCell: UITableViewCell {
    
    
    
   
    @IBOutlet weak var readIndicator: UIView!
    @IBOutlet weak var displayName: UILabel!
    @IBOutlet weak var timeStamp: UILabel!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var profilePic: UIImageView!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        readIndicator.clipsToBounds = true
        readIndicator.layer.cornerRadius = readIndicator.frame.height / 2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

