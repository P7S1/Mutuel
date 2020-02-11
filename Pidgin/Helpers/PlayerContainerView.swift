//
//  PlayerContainerView.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 1/9/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
class PlayerContainerView: UIView {
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    var isMuted = false
    
    override class var layerClass: Swift.AnyClass {
       return AVPlayerLayer.self
     }
    
    func initialize(post : Post, shouldPlay :  Bool){
        DispatchQueue.main.async {
        if post.isVideo{
        self.backgroundColor = .clear
        VideoManager().requestPlayer(post: post) { (completion, playerController) in
            if completion{
                do {
                   try AVAudioSession.sharedInstance().setCategory(.playback)
                } catch(let error) {
                    print(error.localizedDescription)
                }
                let player = playerController?.player
                (self.layer as! AVPlayerLayer).player = player
               (self.layer as! AVPlayerLayer).videoGravity = AVLayerVideoGravity.resizeAspectFill
             /*   self.playerLayer!.frame = self.bounds
                if self.playerLayer != nil{
                self.layer.addSublayer(self.playerLayer!)
                } */
                self.isHidden = false
                (self.layer as! AVPlayerLayer).player?.isMuted = self.isMuted
                if shouldPlay{
                (self.layer as! AVPlayerLayer).player?.play()
                }
                NotificationCenter.default.addObserver( self,
                                                       selector: #selector(self.playerItemDidReachEnd(notification:)),
                name: .AVPlayerItemDidPlayToEndTime,
                object: playerController?.player?.currentItem)
                                // do some magic with path to saved video
            }else{
                print("there was an error")
            }
            
        }
           
        }else{
            print("post must be a video")
            self.pause()
        }
        }
    }
    
    func play(){
     /*   if let player = (self.layer as! AVPlayerLayer).player{
            
        }else{
        if let post = self.post{
        self.initialize(post: post)
        }
        } */
        DispatchQueue.main.async {
            do {
                try AVAudioSession.sharedInstance().setCategory(.multiRoute)
            } catch(let error) {
                print(error.localizedDescription)
            }
            (self.layer as! AVPlayerLayer).player?.isMuted = self.isMuted
            (self.layer as! AVPlayerLayer).player?.play()
        }
    }
    
    func pause(){
        DispatchQueue.main.async {
            (self.layer as! AVPlayerLayer).player?.pause()
            (self.layer as! AVPlayerLayer).player = nil
        }

    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
      //  playerLayer?.frame = self.bounds
    }

@objc func playerItemDidReachEnd(notification: Notification) {
    DispatchQueue.main.async {
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero, completionHandler: nil)
        }
    }
}
}
