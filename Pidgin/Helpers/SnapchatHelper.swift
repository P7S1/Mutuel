//
//  SnapchatHelper.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 4/13/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import SCSDKCreativeKit
import Kingfisher

class SnapchatHelper{
    
    static var shared = SnapchatHelper()
    
    var snapAPI: SCSDKSnapAPI?
    
    init() {
        snapAPI = SCSDKSnapAPI()
    }
    
    
    func share(account : Account){
        if let url = URL(string: account.profileURL ?? ""){
        let resource = ImageResource(downloadURL: url)
        KingfisherManager.shared.retrieveImage(with: resource, options: nil, progressBlock: nil) { result in
            switch result {
                
            case .success(let value):
                ProgressHUD.dismiss()
                self.doSnapKitStuff(image: value.image, account: account)
            case .failure( _):
                ProgressHUD.dismiss()
                self.doSnapKitStuff(image: nil, account: account)
            }
        }
        }else{
            ProgressHUD.dismiss()
            self.doSnapKitStuff(image: nil, account: account)
        }
        
    }
    
    func doSnapKitStuff(image : UIImage?, account : Account){
       let stickerView = SnapchatUserSticker.instanceFromNib() as! SnapchatUserSticker
        stickerView.clipsToBounds = true
        stickerView.layer.cornerRadius = 20
        stickerView.profileImageView.image = image
        stickerView.profileImageView.clipsToBounds = true
        stickerView.profileImageView.layer.cornerRadius = stickerView.profileImageView.frame.height/2
        stickerView.mutuelIcon.clipsToBounds = true
        stickerView.mutuelIcon.layer.cornerRadius = stickerView.mutuelIcon.frame.height/5
        stickerView.usernameLabel.text = "@\(account.username!)"
        stickerView.displayNameLabel.text = account.name
        
        prepareSnap(stickerImage: stickerView.asImage())
    }
    
    func share(post: Post){
        ProgressHUD.show("Loading...")
        if let url = URL(string: post.photoURL){
        let resource = ImageResource(downloadURL: url)
        KingfisherManager.shared.retrieveImage(with: resource, options: nil, progressBlock: nil) { result in
            switch result {
            case .success(let value):
                ProgressHUD.dismiss()
                print("Image: \(value.image). Got from: \(value.cacheType)")
                self.doSnapKitStuff(image: value.image, post: post)
            case .failure(let error):
                ProgressHUD.showError("Error")
                print("Error: \(error)")
            }
        }
        }
        
    }
    
    func doSnapKitStuff(image : UIImage, post : Post){
        print("doing snap kit stuff")
        let stickerView = SnapchatSticker.instanceFromNib() as! SnapchatSticker
        stickerView.username.text = post.creatorUsername
        if post.hasChallenge{
            stickerView.caption.text = post.challengeTitle
        }else{
            stickerView.caption.text = post.caption
        }
        stickerView.imageView.image = image
        if let url = URL(string: post.creatorPhotoURL){
        stickerView.profilePictureView.kf.setImage(with: url)
        }
        stickerView.clipsToBounds = true
        stickerView.layer.cornerRadius = 20
        stickerView.profilePictureView.clipsToBounds = true
        stickerView.profilePictureView.layer.cornerRadius = stickerView.profilePictureView.frame.height/2
        stickerView.playButton.isHidden = !post.isVideo
        stickerView.mutuelIcon.clipsToBounds = true
        stickerView.mutuelIcon.layer.cornerRadius = stickerView.mutuelIcon.frame.height/5
        let stickerImage = stickerView.asImage()
        
        prepareSnap(stickerImage: stickerImage)
    }
    
    func prepareSnap(stickerImage : UIImage){
        let sticker = SCSDKSnapSticker(stickerImage: stickerImage)
        
        
        
        
        let snap = SCSDKNoSnapContent()
        snap.sticker = sticker /* Optional */
        snap.attachmentUrl = "https://itunes.apple.com/app/id1498709902" /* Optional */
        
        shareSnap(content: snap, completionHandler: nil)
    }
    
    func shareSnap(content : SCSDKSnapContent,completionHandler: ((Bool, Error?) ->())?) {
      // This method makes a user of the global UIPasteboard, and calling the method without synchronization might cause
      // UIPasteboard data to be overwritten, while being read from Snapchat. Either synchronize the method call yourself,
      // or disable user interaction until the share is over.
      snapAPI?.startSending(content) { (error: Error?) in
        
        if error == nil{
            print("snap successful")
        }else{
            print("error \(error!.localizedDescription)")
        }
      }
    }
    
}
