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
    @IBOutlet weak var collectionView: UICollectionView!
    var bubblePictures : BubblePictures!

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
    
    func setUpBubblePictures(channel : Channel){
        var bubblePics = [BPCellConfigFile]()
        self.profilePic.isHidden = true
        let layoutConfigurator = BPLayoutConfigurator(
        backgroundColorForTruncatedBubble: UIColor.secondarySystemBackground,
        fontForBubbleTitles: UIFont.systemFont(ofSize: 15, weight: .regular),
        colorForBubbleBorders: UIColor.clear,
        colorForBubbleTitles: UIColor.label,
        maxCharactersForBubbleTitles: 2,
        maxNumberOfBubbles: 3,
        displayForTruncatedCell: .number((channel.members.count-1)),
        direction: .leftToRight,
        alignment: .center)
        
        for member in channel.members{
            if member != User.shared.uid && bubblePics.count < 2{
            if let string = channel.profilePics.value(forKey: member) as? String,
                let url = URL(string: string){
                    let bubble = BPCellConfigFile(imageType: .URL(url), title: "")
            bubblePics.append(bubble)
            }
            }
            
        }
        
        self.bubblePictures = BubblePictures(collectionView: collectionView, configFiles: bubblePics, layoutConfigurator: layoutConfigurator)

    }

}

