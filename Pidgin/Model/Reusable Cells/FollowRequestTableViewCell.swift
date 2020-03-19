//
//  FollowRequestTableViewCell.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/19/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit

class FollowRequestTableViewCell: UITableViewCell {
    
    @IBOutlet weak var profilePictureView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var declineButton: UIButton!
    
    var acceptAction : (()->())?
    
    var declineAction : (()->())?
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        acceptButton.roundCorners()
        declineButton.roundCorners()
        profilePictureView.layer.masksToBounds = true
        profilePictureView.layer.cornerRadius = profilePictureView.frame.height/2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func acceptButtonPressed(_ sender: Any) {
        acceptAction?()
    }
    @IBAction func declineButtonPressed(_ sender: Any) {
        declineAction?()
    }
    
}
