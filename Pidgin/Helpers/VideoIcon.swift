//
//  VideoIcon.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 1/16/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit

class VideoIcon: UIImageView {
    var blinkStatus = false
    var shouldBlink = true
    var timer = Timer()
    override func awakeFromNib() {
        if shouldBlink{
        timer = Timer(timeInterval: 1.0, target: self, selector: #selector(blink), userInfo: nil, repeats: true)
        
        RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
            
        self.layer.shadowOpacity = 0.3
        self.layer.shadowRadius = 2.0
        self.layer.shadowColor = UIColor.darkGray.cgColor
        }
    }
    
    @objc func blink () {
        if self.shouldBlink{
        if blinkStatus == false {
            UIView.animate(withDuration: 0.75) {
                self.alpha = 0
            }
            blinkStatus = true
        } else {
            UIView.animate(withDuration: 0.75) {
                self.alpha = 1
            }
            blinkStatus = false
        }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
       super.init(coder: aDecoder)
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
