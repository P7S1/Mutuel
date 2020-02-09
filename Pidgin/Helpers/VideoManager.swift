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
    
     func requestPlayer(post : Post, completion: @escaping (Bool,AVPlayerViewController?) -> Void){
        if let player = VideoManager.shared[post.postID] as? AVPlayerViewController{
            completion(true,player)
        }else{
            if let stringUrl = post.videoURL, let url = URL(string: stringUrl){
                let player = AVPlayer(url: url)
                player.automaticallyWaitsToMinimizeStalling = false
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
