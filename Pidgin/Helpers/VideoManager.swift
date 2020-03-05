//
//  VideoManager.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 1/10/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import Foundation
import AVKit
class VideoManager{
    static var shared = NSMutableDictionary()
    var observer: NSKeyValueObservation?
    
     func requestPlayer(post : Post, completion: @escaping (Bool,AVPlayerViewController?) -> Void){
        if let player = VideoManager.shared[post.postID] as? AVPlayerViewController{
            completion(true,player)
        }else{
            if let stringUrl = post.videoURL, let url = URL(string: stringUrl){
                let asset = AVAsset(url: url)
                
                let assetKeys = [
                    "playable",
                    "hasProtectedContent"
                ]
                let playerItem = AVPlayerItem(asset: asset,
                                             automaticallyLoadedAssetKeys: assetKeys)
            
                
                // Register as an observer of the player item's status property
                self.observer = playerItem.observe(\.status, options:  [.new, .old], changeHandler: { (playerItem, change) in
                    if playerItem.status == .readyToPlay {
                        //Do your work here
                        print("ready to play")
                    }
                })
                
                let player = AVPlayer(playerItem: playerItem)
                
                player.actionAtItemEnd = .none
                player.externalPlaybackVideoGravity = .resizeAspectFill
                let playerController = AVPlayerViewController()
                playerController.player = player
                VideoManager.shared.setValue(playerController, forKey: post.postID)
                completion(true,playerController)
            }else{
                print("error, postID:\(post.postID)")
            }
        }
    }
    
    func destroyVideos(){
        for item in VideoManager.shared{
            if let playerControllerView = item.value as? AVPlayerViewController{
                playerControllerView.player?.pause()
                playerControllerView.player = nil
            }
        }
        VideoManager.shared.removeAllObjects()
    }
    
    
}
