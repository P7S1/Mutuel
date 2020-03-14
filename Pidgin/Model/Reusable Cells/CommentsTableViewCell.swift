//
//  CommentsTableViewCell.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 1/25/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import GiphyUISDK
import GiphyCoreSDK
import SkeletonView
import SwiftyGif
class CommentsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var profilePictureView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var captionLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var viewRepliesLabel: UILabel!
    
    @IBOutlet weak var gifView: UIImageView!
    @IBOutlet weak var gifViewHeight: NSLayoutConstraint!
    
    
    var likeTapAction : (()->())?
    
    var moreTapAction : (()->())?
    
    var profileTapAction : (()->())?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.gifView.isSkeletonable = true
        self.profilePictureView.isSkeletonable = true
        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        moreButton.addTarget(self, action: #selector(moreButtonTapped), for: .touchUpInside)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setUpGestures(){
      let tap = UITapGestureRecognizer(target: self, action: #selector(profileButtonTapped))
        profilePictureView.addGestureRecognizer(tap)
    }
    
    @objc func moreButtonTapped(){
        moreTapAction?()
        print("more button tapped")
    }
    
    @objc func likeButtonTapped(){
        likeTapAction?()
        print("like button tapped")
    }
    
    @objc func profileButtonTapped(){
        profileTapAction?()
        print("profile button tapped")
    }

    func setUnLikedState(){
        self.likeButton.tintColor = .secondaryLabel
        self.likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
        self.likeButton.setTitleColor(.secondaryLabel, for: .normal)
    }
    
    func setLikedState(){
        self.likeButton.tintColor = .systemPink
        self.likeButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        self.likeButton.setTitleColor(.systemPink, for: .normal)
    }
    
    func setGifMediaView(comment : Comment){
        gifView.layer.masksToBounds = true
        gifView.layer.cornerRadius = 10
        if let id = comment.mediaID{
            let gradient = SkeletonGradient(baseColor: UIColor.secondarySystemBackground)
            self.gifView.showAnimatedGradientSkeleton(usingGradient: gradient)
            GiphyCore.shared.gifByID(id) { (response, error) in
                if let media = response?.data {
                    if let gifURL = media.url(rendition: .fixedWidth, fileType: .gif),
                        let url = URL(string: gifURL){
                        DispatchQueue.main.async {
                            DispatchQueue.main.async {
                        self.gifView.setGifFromURL(url)
                            }
                        }
                }
                }
            }
        }else{
            gifViewHeight.constant = 0
        }
    }
}
