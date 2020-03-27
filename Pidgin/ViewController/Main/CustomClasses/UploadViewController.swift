//
//  UploadViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/1/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import CarbonKit
import ARKit
import GiphyCoreSDK
import Photos
import CropViewController
class UploadViewController: UIViewController, CarbonTabSwipeNavigationDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var photoVC : PhotoPickerViewController!
    
    var cameraVC : CameraVC!
    
    var challengeVC : ChallengesViewController!
    
    var gifVC : GifViewController!
    
    var challenge : Challenge?
    
    var challengeDay : ChallengeDay?
    
    var isChallenge = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .systemBackground
        
        if isChallenge{
         navigationItem.title = "Challenge Post"
        }else{
         navigationItem.title = "New Post"
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let discoverStoryboard = UIStoryboard(name: "Discover", bundle: nil)
        photoVC = discoverStoryboard.instantiateViewController(withIdentifier: "PhotoPickerViewController") as? PhotoPickerViewController
        photoVC.photoPickerDelegate = self
        
        cameraVC = storyboard.instantiateViewController(withIdentifier: "CameraVC") as? CameraVC
        cameraVC.cameraVCDelegate = self
        
        gifVC = discoverStoryboard.instantiateViewController(withIdentifier: "GifViewController") as? GifViewController
        gifVC.gifDeleagte = self
        
        challengeVC = discoverStoryboard.instantiateViewController(withIdentifier: "ChallengesViewController") as? ChallengesViewController
        
        let items = ["Photo", "GIF", "Camera"]
        
        let carbonTabSwipeNavigation = CarbonSwipe(items: items, delegate: self)
        carbonTabSwipeNavigation.configure(items: items, vc: self)
        carbonTabSwipeNavigation.delegate = self
        carbonTabSwipeNavigation.carbonSegmentedControl?.indicatorPosition = .top

        self.setDismissButton()
        // Do any additional setup after loading the view.
    }
    
    override func handleDismissButton() {
        ProgressHUD.dismiss()
        super.handleDismissButton()
    }
    
    func carbonTabSwipeNavigation(_ carbonTabSwipeNavigation: CarbonTabSwipeNavigation, viewControllerAt index: UInt) -> UIViewController {
        if index == 0{
         return photoVC
        }else if index == 1{
         return gifVC
        }else{
         return cameraVC
        }
        // return viewController at index
    }

    func barPosition(for carbonTabSwipeNavigation: CarbonTabSwipeNavigation) -> UIBarPosition {
        return UIBarPosition.bottom
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension UploadViewController : GifDelegate, PhotoPickerDelegate, CropViewControllerDelegate, CameraDelegate{
    func didFinishProcessingVideo(url: URL) {
        
        FollowersHelper().generateThumbnail(path: url) { (image) in
            self.presentSendToUserVC(image: image, video: url, photoSize: image.size)
        }
    }
    
    func didTakePhoto(image: UIImage) {
        let vc = CropViewController(image: image)
        vc.aspectRatioLockEnabled = false
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func didSelectItem(gif: GPHMedia, vc: GifViewController) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let sendVC = storyboard.instantiateViewController(withIdentifier: "SendToUserViewController") as! SendToUserViewController
        sendVC.isGIF = true
        sendVC.media = gif
        sendVC.challenge = challenge
        sendVC.challengeDay = challengeDay
        navigationController?.pushViewController(sendVC, animated: true)
    }
    
    func didSelectAsset(asset: PHAsset, photoPicker: UIViewController) {
        print("selected asset")
        if asset.mediaType == .video{
            
            let manager = PHImageManager.default()
            let options = PHVideoRequestOptions()
            options.deliveryMode = .automatic
            
            let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            ProgressHUD.show("Fetching from iCloud")
            manager.requestExportSession(forVideo: asset, options: options, exportPreset: AVAssetExportPresetMediumQuality) { (exporter, info) in
                ProgressHUD.show("Exporting")
                let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                let myDocumentPath = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("temp.mp4").absoluteString
                _ = NSURL(fileURLWithPath: myDocumentPath)
                let documentsDirectory2 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
                let filePath = documentsDirectory2.appendingPathComponent("video.mp4")
                self.deleteFile(filePath: filePath as NSURL)

                //Check if the file already exists then remove the previous file
                if FileManager.default.fileExists(atPath: myDocumentPath) {
                    do { try FileManager.default.removeItem(atPath: myDocumentPath)
                    } catch let error { print(error) }
                }
                
                
                exporter?.outputURL = filePath
                exporter?.outputFileType = AVFileType.mov
                exporter?.exportAsynchronously(completionHandler: {
                    FollowersHelper().generateThumbnail(path: (exporter?.outputURL!)!) { (image) in
                        DispatchQueue.main.async {
                            ProgressHUD.dismiss()
                            self.presentSendToUserVC(image: image , video: exporter?.outputURL!, photoSize: size)
                        }
                    }

                    
                })

            }
            
            
        }else if asset.mediaType == .image{
            ProgressHUD.show("Loading Photo")
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.version = .original
            options.isSynchronous = true
            
            let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            manager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { (image, info) in
                if image != nil{
                    ProgressHUD.dismiss()
                let vc = CropViewController(image: image!)
                    vc.aspectRatioLockEnabled = false
                    vc.delegate = self
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
            
        }
        
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        print("did crop image")
        presentSendToUserVC(image: image, video: nil, photoSize: image.size)
    }
    
    func presentSendToUserVC(image : UIImage, video : URL?, photoSize : CGSize){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SendToUserViewController") as! SendToUserViewController
        vc.video = video
        vc.image = image
        vc.photoSize = photoSize
        vc.challenge = self.challenge
        vc.challengeDay = self.challengeDay
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func deleteFile(filePath:NSURL) {
        guard FileManager.default.fileExists(atPath: filePath.path!) else {
            return
        }
        
        do { try FileManager.default.removeItem(atPath: filePath.path!)
        } catch { fatalError("Unable to delete file: \(error)") }
    }
    
    
}
 
