//
//  BlockedUserTableViewCell.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/22/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit

class BlockedUserTableViewCell: UITableViewCell {

    
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var username: UILabel!
    var unblockAction : (()->())?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        removeButton.roundCorners()
    }

    @IBAction func removeButtonPressed(_ sender: Any) {
        unblockAction?()
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
