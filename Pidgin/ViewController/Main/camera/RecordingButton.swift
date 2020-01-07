//
//  RecordingButton.swift
//  Recording Animation Layer
//
//  Created by Dotsquares on 1/30/17.
//  Copyright © 2017 Dotsquares. All rights reserved.
//

import UIKit


protocol RecordingButtonDelegate {
    func didStartCapture();
    func didEndCapture();
}

class RecordingButton: UIButton {

    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     */
    
    
    // setter properties
    var innerCircleRadious: CGFloat = 35;
    var outerCircleRadious: CGFloat = 40;
    var outlineColor: UIColor = UIColor.white;
    var innerCircleColor: UIColor = UIColor.white;
    var progessColor: UIColor = .systemRed;
    var isContinue :Bool = false;
    var recordingDuration: CGFloat = 15;
    var delegate: RecordingButtonDelegate?;
    
    var isCompleteMode :Bool = false;
    
    
    var isRecordingState: Bool = false;
    var innerCirlceFrame: CGRect!;
    var innerCircleCornerRadious: CGFloat = 0;
    
    var isPlayingProgress: Bool = false;
    var isStopRecording: Bool = false;
    
    var startProgressValue: CGFloat = 0;
    var endProgressValue: CGFloat = 0;
    
    
    var timer: Timer!;
    
    
    func setOutlineColor(color: UIColor) {
        outlineColor = color;
    }
    
    func setInnerCircleColor(color: UIColor) {
        innerCircleColor = color;
    }
    
    func setprogessColor(color: UIColor) {
        progessColor = color;
    }
    
    func setoutlineRadious(radious: CGFloat) {
        outerCircleRadious = radious;
    }
    
    func setInnerCircleRadious(radious: CGFloat) {
        innerCircleRadious = radious;
    }
    
    override func draw(_ rect: CGRect) {
        // Drawing code
        
        let outerCircle = UIBezierPath();
        let startAngle = 0;
        let endAngle = M_PI * 2;
        outerCircle.addArc(withCenter: CGPoint.init(x: rect.size.width/2, y: rect.size.height/2), radius: outerCircleRadious, startAngle: CGFloat(startAngle), endAngle:CGFloat(endAngle), clockwise: true);
        outerCircle.lineWidth=5.0;
        outlineColor.set();
        outerCircle.stroke();
        
        
        let innerCircle = UIBezierPath();
        if isRecordingState {
            //let innerCircleRect = innerCircle.bounds;
            var newUpdatedFrame = innerCirlceFrame;
            if isPlayingProgress {
                
                let progressCircle = UIBezierPath();
                progressCircle.addArc(withCenter: CGPoint.init(x: rect.size.width/2, y: rect.size.height/2), radius: 40, startAngle: CGFloat(startProgressValue), endAngle:CGFloat(endProgressValue), clockwise: true);
                progressCircle.lineWidth=5.0;
                progessColor.set();
                progressCircle.stroke();
                
            }
            else
            {
                newUpdatedFrame?.origin.x += 1;
                newUpdatedFrame?.origin.y += 1;
                newUpdatedFrame?.size.width -= 2;
                newUpdatedFrame?.size.height -= 2;
            }
            
            let circleToRect = UIBezierPath.init(roundedRect: newUpdatedFrame!, cornerRadius: innerCircleCornerRadious);
            innerCircleColor.setFill();
            circleToRect.fill();
        }
        else
        {
            innerCircle.addArc(withCenter: CGPoint.init(x: rect.size.width/2, y: rect.size.height/2), radius: innerCircleRadious, startAngle: CGFloat(startAngle), endAngle:CGFloat(endAngle), clockwise: true);
            innerCircleColor.setFill();
            innerCircle.fill();
            innerCirlceFrame = innerCircle.bounds;
            innerCircleCornerRadious = innerCirlceFrame.size.width/2;
        }
        
    }
    
    
    func record() {
        if !isContinue {
            UIView.animate(withDuration: 0.2) {
                self.setInnerCircleColor(color: .systemRed)
            }
            isContinue = true;
            timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.playStateChangeAnimation), userInfo: nil, repeats: true);
        }
        else
        {
            stopRecord();
        }
    }
    
    func stopRecord() {
        delegate?.didEndCapture();
        UIView.animate(withDuration: 0.2) {
            self.setInnerCircleColor(color: .white)
        }
        isContinue = false;
        isStopRecording=true;
        isPlayingProgress = false;
        isRecordingState = false;
        endProgressValue=0;
        //innerCircleRadious=25;
        isCompleteMode = true;
//        timer.invalidate();
        timer = nil;
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.restoreDefaultState), userInfo: nil, repeats: true);
        
    }
    
    @objc func restoreDefaultState() {
        //repeat{
        if innerCircleRadious<35 {
            innerCircleRadious += 1;
        }
        else
        {
            isCompleteMode = false;
            innerCircleCornerRadious -= 1;
        }
        setNeedsDisplay();
        if innerCircleRadious>=35 {
            
            timer.invalidate();
            timer = nil;

        }
        setNeedsDisplay();
        
    }
    
    @objc func playProgress() {
        endProgressValue += (CGFloat(M_PI * 2)/recordingDuration * 0.05);
        let endAngle = M_PI * 2;
        if endProgressValue > CGFloat(endAngle) {
            stopRecord();
        }
        setNeedsDisplay();
    }
    
    @objc func playStateChangeAnimation() {
        
        
        //repeat{
        if innerCircleRadious>15 {
            innerCircleRadious -= 1;
        }
        else
        {
            isRecordingState = true;
            innerCircleCornerRadious -= 1;
        }
        setNeedsDisplay();
        
        //}while innerCircleCornerRadious>0
        
        if innerCircleCornerRadious<=5 {
            timer.invalidate();
            timer=nil;
            isRecordingState = true;
            isPlayingProgress = true;
            
            timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(self.playProgress), userInfo: nil, repeats: true);
            delegate?.didStartCapture();
        }
        
    }

}
