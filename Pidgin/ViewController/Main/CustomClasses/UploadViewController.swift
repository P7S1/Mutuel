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
    
    var arVC : ARCameraVC?
    
    var gifVC : GifViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .systemBackground
        
        navigationItem.title = "New Post"
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let discoverStoryboard = UIStoryboard(name: "Discover", bundle: nil)
        photoVC = discoverStoryboard.instantiateViewController(withIdentifier: "PhotoPickerViewController") as? PhotoPickerViewController
        photoVC.photoPickerDelegate = self
        
        cameraVC = storyboard.instantiateViewController(withIdentifier: "CameraVC") as? CameraVC
        cameraVC.cameraVCDelegate = self
        
        gifVC = discoverStoryboard.instantiateViewController(withIdentifier: "GifViewController") as? GifViewController
        gifVC.gifDeleagte = self
        
        var items = ["Photos", "GIFs", "Camera"]
        
        if ARFaceTrackingConfiguration.isSupported{
            self.arVC = storyboard.instantiateViewController(withIdentifier: "ARCameraVC") as? ARCameraVC
            self.arVC?.cameraDelegate = self
            items.append("AR")
        }
        
        let carbonTabSwipeNavigation = CarbonSwipe(items: items, delegate: self)
        carbonTabSwipeNavigation.configure(items: items, vc: self)
        carbonTabSwipeNavigation.delegate = self
        carbonTabSwipeNavigation.carbonSegmentedControl?.indicatorPosition = .top

        self.setDismissButton()
        // Do any additional setup after loading the view.
    }
    
    func carbonTabSwipeNavigation(_ carbonTabSwipeNavigation: CarbonTabSwipeNavigation, viewControllerAt index: UInt) -> UIViewController {
        if index == 0{
         return photoVC
        }else if index == 1{
         return gifVC
        }else if index == 2{
         return cameraVC
        }else{
         if ARFaceTrackingConfiguration.isSupported{
            return arVC!
         }else{
            return cameraVC
            }
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
        navigationController?.pushViewController(sendVC, animated: true)
    }
    
    func didSelectAsset(asset: PHAsset, photoPicker: UIViewController) {
        print("selected asset")
        if asset.mediaType == .video{
            
            let manager = PHImageManager.default()
            let options = PHVideoRequestOptions()
            options.deliveryMode = .automatic
            
            let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            
            manager.requestExportSession(forVideo: asset, options: options, exportPreset: AVAssetExportPreset960x540) { (exporter, info) in
                
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
                            self.presentSendToUserVC(image: image , video: exporter?.outputURL!, photoSize: size)
                        }
                    }

                    
                })

            }
            
            
        }else if asset.mediaType == .image{
         
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.version = .original
            options.isSynchronous = true
            
            let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            manager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { (image, info) in
                if image != nil{
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
 
