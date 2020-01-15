//
//  VideoHelper.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 12/24/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//
import AVFoundation
import Foundation
import GiphyUISDK
class VideoHelper{
    static func videoCompositionInstruction(_ track: AVCompositionTrack, asset: AVAsset, mediaView : GPHMediaView, renderSize: CGSize, imageView: UIImageView)
    -> AVMutableVideoCompositionLayerInstruction {
    let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
  let assetTrack = asset.tracks(withMediaType: .video)[0]
        //let adjustCoordinates = CGAffineTransform(translationX: mediaView.frame.origin.x, y: mediaView.frame.origin.y)
        //print("coordinates: x: \(mediaView.frame.origin.x) y: \(mediaView.frame.origin.y)")
        //instruction.setTransform(adjustCoordinates, at: CMTime.zero)
         
      /*  let radians:Double = atan2( Double(mediaView.transform.b), Double(mediaView.transform.a))
        let degrees:CGFloat = CGFloat(radians * 180 / .pi)
        
        //let adjustSize = CGAffineTransform(scaleX: mediaView.transform.a, y: mediaView.transform.d).translatedBy(x: mediaView.frame.origin.x, y: mediaView.frame.origin.y).rotated(by: degrees).concatenating(mediaView.transform) */
        let scaleX = renderSize.width / imageView.frame.width
        let scaleY = renderSize.height / imageView.frame.height
        let rectangle = CGRect(x: 0, y: 0, width: assetTrack.naturalSize.applying(assetTrack.preferredTransform).width, height:  assetTrack.naturalSize.applying(assetTrack.preferredTransform).height)
        let rectangle2 = CGRect(x: mediaView.frame.origin.x * scaleX , y: mediaView.frame.origin.y * scaleY, width: mediaView.frame.width, height: mediaView.frame.height)
        let adjustSize = self.transformFromRect(from: rectangle, toRect: rectangle2).scaledBy(x: scaleX, y: scaleY)
        instruction.setTransform(adjustSize, at: CMTime.zero)
    
    return instruction
    }
    
    static func createGIFAnimation(url:URL) -> CAKeyframeAnimation?{

        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let frameCount = CGImageSourceGetCount(src)

        // Total loop time
        var time : Float = 0

        // Arrays
        var framesArray = [AnyObject]()
        var tempTimesArray = [NSNumber]()

        // Loop
        for i in 0..<frameCount {

            // Frame default duration
            var frameDuration : Float = 0.1;

            let cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(src, i, nil)
            guard let framePrpoerties = cfFrameProperties as? [String:AnyObject] else {return nil}
            guard let gifProperties = framePrpoerties[kCGImagePropertyGIFDictionary as String] as? [String:AnyObject]
                else { return nil }

            // Use kCGImagePropertyGIFUnclampedDelayTime or kCGImagePropertyGIFDelayTime
            if let delayTimeUnclampedProp = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber {
                frameDuration = delayTimeUnclampedProp.floatValue
            }
            else{
                if let delayTimeProp = gifProperties[kCGImagePropertyGIFDelayTime as String] as? NSNumber {
                    frameDuration = delayTimeProp.floatValue
                }
            }

            // Make sure its not too small
            if frameDuration < 0.011 {
                frameDuration = 0.100;
            }

            // Add frame to array of frames
            if let frame = CGImageSourceCreateImageAtIndex(src, i, nil) {
                tempTimesArray.append(NSNumber(value: frameDuration))
                framesArray.append(frame)
            }

            // Compile total loop time
            time = time + frameDuration
        }

        var timesArray = [NSNumber]()
        var base : Float = 0
        for duration in tempTimesArray {
            timesArray.append(NSNumber(value: base))
            base = base + ( duration.floatValue / time )
        }

        // From documentation of 'CAKeyframeAnimation':
        // the first value in the array must be 0.0 and the last value must be 1.0.
        // The array should have one more entry than appears in the values array.
        // For example, if there are two values, there should be three key times.
        timesArray.append(NSNumber(value: 1.0))

        // Create animation
        let animation = CAKeyframeAnimation(keyPath: "contents")

        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.duration = CFTimeInterval(time)
        animation.repeatCount = Float.greatestFiniteMagnitude;
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.values = framesArray
        animation.keyTimes = timesArray
        //animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.calculationMode = CAAnimationCalculationMode.discrete

        return animation;
    }
    static func transformFromRect(from source: CGRect, toRect destination: CGRect) -> CGAffineTransform {
        return CGAffineTransform.identity
            .translatedBy(x: destination.midX - source.midX, y: destination.midY - source.midY)
            .scaledBy(x: destination.width / source.width, y: destination.height / source.height)
    }
    
    static func orientationFromTransform(_ transform: CGAffineTransform)
        -> (orientation: UIImage.Orientation, isPortrait: Bool) {
            var assetOrientation = UIImage.Orientation.up
      var isPortrait = false
      if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
        assetOrientation = .right
        isPortrait = true
      } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
        assetOrientation = .left
        isPortrait = true
      } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
        assetOrientation = .up
      } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
        assetOrientation = .down
      }
      return (assetOrientation, isPortrait)
    }
    
    static func getSuitableSize(goalFrame : CGSize, ratio : CGFloat) -> CGSize{
        if goalFrame.width > goalFrame.height {
            let newHeight = goalFrame.width / ratio
            return CGSize(width: goalFrame.width, height: newHeight)
        }
        else{
            let newWidth = goalFrame.height * ratio
            return CGSize(width: newWidth, height: goalFrame.height)
        }
    }
    
    static func calculateRectOfImageInImageView(imageView: UIImageView) -> CGRect {
        let imageViewSize = imageView.frame.size
        let imgSize = imageView.image?.size

        guard let imageSize = imgSize, imgSize != nil else {
            return CGRect.zero
        }

        let scaleWidth = imageViewSize.width / imageSize.width
        let scaleHeight = imageViewSize.height / imageSize.height
        let aspect = fmin(scaleWidth, scaleHeight)

        var imageRect = CGRect(x: 0, y: 0, width: imageSize.width * aspect, height: imageSize.height * aspect)
        // Center image
        imageRect.origin.x = (imageViewSize.width - imageRect.size.width) / 2
        imageRect.origin.y = (imageViewSize.height - imageRect.size.height) / 2

        // Add imageView offset
        imageRect.origin.x += imageView.frame.origin.x
        imageRect.origin.y += imageView.frame.origin.y

        return imageRect
    }
    
    static func convertVideo(toMPEG4FormatForVideo inputURL: URL, outputURL: URL, handler: @escaping (AVAssetExportSession) -> Void) {
        //try! FileManager.default.removeItem(at: outputURL)
        let asset = AVURLAsset(url: inputURL as URL, options: nil)

        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1280x720)!
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.exportAsynchronously(completionHandler: {
            handler(exportSession)
        })
    }
}
