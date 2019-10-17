//
//  CameraVC.swift
//  PhotoVideoEditor
//
//  Created by Faris Albalawi on 11/12/18.
//  Copyright © 2018 Faris Albalawi. All rights reserved.
//

import UIKit
import ARKit
import SvrfSDK
import NextLevel
class ARCameraVC: UIViewController {
    
    
    let recordingQueue = DispatchQueue(label: "recordingThread", attributes: .concurrent)
    let caprturingQueue = DispatchQueue(label: "capturingThread", attributes: .concurrent)
    
    var flashEnabled = false
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var searchResultsView: UICollectionView!
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    @IBOutlet weak var captureButton : UIView!
    
    
    
    var searchResults: [SvrfMedia] = []
    let contentUpdater = VirtualContentUpdater()
    let remoteFaceFilter = RemoteFaceFilter()
    
  
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.run(configuration)
        do{
        try NextLevel.shared.start()
        }catch{
            print("NextLevel start error: \(error)")
        }
    
    }
    override func viewWillDisappear(_ animated: Bool) {
        ProgressHUD.dismiss()
        NextLevel.shared.stop()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        searchResultsView.delegate = self
        searchResultsView.dataSource = self
        
        // ContentUpdater will tell the ARSCNView what to draw
        sceneView.delegate = contentUpdater
        //sceneView.session.delegate = self

        // ContentUpdater's virtual face node will dictate what Face Filter to render
        contentUpdater.virtualFaceNode = remoteFaceFilter
        
        setupCamera()
        
        searchBar.delegate = self
                
        let captureTap = UITapGestureRecognizer(target: self, action: #selector(takePhoto))
        captureButton.addGestureRecognizer(captureTap)
        
        let videoPress = UILongPressGestureRecognizer(target: self, action: #selector(startRecording))
        captureButton.addGestureRecognizer(videoPress)
        getTrendingFilters()
        
    }
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBAction func dismissButton(_ sender: Any) {
        self.view.window!.rootViewController?.dismiss(animated: true, completion: nil)

    }
    @IBAction func goBackButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func takePhoto(){
        NextLevel.shared.capturePhotoFromVideo()
        print("photo button tapped")
    }
    
    @objc func startRecording(sender : UILongPressGestureRecognizer){
        
        switch sender.state {
        case .began:
            print("video started recording")
            NextLevel.shared.record()
            //start recording
        case .ended:
            print("video paused")
            NextLevel.shared.pause()
            stopRecording()
            break
        default:
            break
        }
    }
    
    func stopRecording(){
        if let session = NextLevel.shared.session {
        

                    session.mergeClips(usingPreset: AVAssetExportPresetHighestQuality, completionHandler: { (url: URL?, error: Error?) in
                        if let url = url {
                            print("video successfulyl saved")
                        } else if let _ = error {
                            print("failed to merge clips at the end of capture \(String(describing: error))")
                        }
                    })
            
        }else{
            print("failed setting up session")
        }
    }
    
    
    func getTrendingFilters(){
       let searchOptions = SvrfOptions(
          type: [._3d],
          stereoscopicType: nil,
          category: nil,
          size: nil,
          minimumWidth: nil,
          isFaceFilter: nil,
          hasBlendShapes: nil,
          requiresBlendShapes: nil,
          pageNum: nil
        )
        _ = SvrfSDK.getTrending(options: searchOptions, onSuccess: { (allMedia, nextPageNum) in
            print("got \(allMedia.count) results")
            self.searchResults = allMedia
            self.searchResultsView.reloadData()
        })
    }
    
    
}
//More Delegate methods
extension ARCameraVC: UISearchBarDelegate {
    internal func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        ProgressHUD.show()
        // Hide keyboard
        searchBar.resignFirstResponder()
        
        // Show the searchResultsView
        searchResultsView.isHidden = false
        
        guard let query = searchBar.text else {
            return
        }
        
        print("Searching for \(query)")
        
        let searchOptions = SvrfOptions(
          type: [._3d],
          stereoscopicType: nil,
          category: nil,
          size: nil,
          minimumWidth: nil,
          isFaceFilter: nil,
          hasBlendShapes: nil,
          requiresBlendShapes: nil,
          pageNum: nil
        )
        
        _ = SvrfSDK.search(query: query, options: searchOptions, onSuccess: { (allMedia, nextPageNum)  in
          print("got \(allMedia.count) results")
            ProgressHUD.dismiss()
            self.searchResults = allMedia
            self.searchResultsView.reloadData()
        }, onFailure: { (err) in
            ProgressHUD.showError("No Results")
          print("Could not search for FaceFilters: \(err)")
        })
    }
}

//Collection view extension
extension ARCameraVC: UICollectionViewDataSource, UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    print(searchResults.count)
    return searchResults.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

    guard let cell = searchResultsView.dequeueReusableCell(withReuseIdentifier: "SearchResultCell", for: indexPath) as? SearchCollectionViewCell else {
      return UICollectionViewCell()
    }

    cell.setupWith(media: searchResults[indexPath.row])

    return cell
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let media = searchResults[indexPath.row]
    
    ProgressHUD.show()
    
    remoteFaceFilter.loadFaceFilter(media: media, sceneView: sceneView)

    // Result selected
    // Do something with the resulting media when it's selected
  }
}
    

extension ARCameraVC{
    func cropToBounds(image: UIImage, width: Double, height: Double) -> UIImage {

        let cgimage = image.cgImage!
        let contextImage: UIImage = UIImage(cgImage: cgimage)
        let contextSize: CGSize = contextImage.size
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(width)
        var cgheight: CGFloat = CGFloat(height)

        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }

        let rect: CGRect = CGRect(x: posX, y: posY, width: cgwidth, height: cgheight)

        // Create bitmap image from context using the rect
        let imageRef: CGImage = cgimage.cropping(to: rect)!

        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage(cgImage: imageRef, scale: image.scale, orientation: image.imageOrientation)

        return image
    }
}

extension ARCameraVC {

 func setupCamera() {
    // setup physical camera, NextLevel
    NextLevel.shared.delegate = self
    NextLevel.shared.deviceDelegate = self
    NextLevel.shared.videoDelegate = self
    NextLevel.shared.photoDelegate = self
    
    NextLevel.shared.captureMode = .arKit

    // modify .videoConfiguration, .audioConfiguration, .photoConfiguration properties
    // Compression, resolution, and maximum recording time options are available
    NextLevel.shared.videoConfiguration.maximumCaptureDuration = CMTimeMakeWithSeconds(5, preferredTimescale: 600)
    NextLevel.shared.audioConfiguration.bitRate = 44000
    
}
}

extension ARCameraVC : NextLevelVideoDelegate{
    func nextLevel(_ nextLevel: NextLevel, didUpdateVideoZoomFactor videoZoomFactor: Float) {
        
    }
    
    
    
    func nextLevel(_ nextLevel: NextLevel, willProcessRawVideoSampleBuffer sampleBuffer: CMSampleBuffer, onQueue queue: DispatchQueue) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, renderToCustomContextWithImageBuffer imageBuffer: CVPixelBuffer, onQueue queue: DispatchQueue) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, willProcessFrame frame: AnyObject, timestamp: TimeInterval, onQueue queue: DispatchQueue) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didSetupVideoInSession session: NextLevelSession) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didSetupAudioInSession session: NextLevelSession) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didStartClipInSession session: NextLevelSession) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didCompleteClip clip: NextLevelClip, inSession session: NextLevelSession) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didAppendVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didSkipVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didAppendVideoPixelBuffer pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, inSession session: NextLevelSession) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didSkipVideoPixelBuffer pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, inSession session: NextLevelSession) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didAppendAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didSkipAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didCompleteSession session: NextLevelSession) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didCompletePhotoCaptureFromVideoFrame photoDict: [String : Any]?) {
        print("did complete photo capture from video frame")
    }
    
    
}

extension ARCameraVC : NextLevelDelegate{
    func nextLevel(_ nextLevel: NextLevel, didUpdateVideoConfiguration videoConfiguration: NextLevelVideoConfiguration) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didUpdateAudioConfiguration audioConfiguration: NextLevelAudioConfiguration) {
        
    }
    
    func nextLevelSessionWillStart(_ nextLevel: NextLevel) {
        
    }
    
    func nextLevelSessionDidStart(_ nextLevel: NextLevel) {
        
    }
    
    func nextLevelSessionDidStop(_ nextLevel: NextLevel) {
        
    }
    
    func nextLevelSessionWasInterrupted(_ nextLevel: NextLevel) {
        
    }
    
    func nextLevelSessionInterruptionEnded(_ nextLevel: NextLevel) {
        
    }
    
    func nextLevelCaptureModeWillChange(_ nextLevel: NextLevel) {
        
    }
    
    func nextLevelCaptureModeDidChange(_ nextLevel: NextLevel) {
        
    }
    
    
}

extension ARCameraVC : NextLevelPhotoDelegate{
    func nextLevel(_ nextLevel: NextLevel, willCapturePhotoWithConfiguration photoConfiguration: NextLevelPhotoConfiguration) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didCapturePhotoWithConfiguration photoConfiguration: NextLevelPhotoConfiguration) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didProcessPhotoCaptureWith photoDict: [String : Any]?, photoConfiguration: NextLevelPhotoConfiguration) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didProcessRawPhotoCaptureWith photoDict: [String : Any]?, photoConfiguration: NextLevelPhotoConfiguration) {
        
    }
    
    func nextLevelDidCompletePhotoCapture(_ nextLevel: NextLevel) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didFinishProcessingPhoto photo: AVCapturePhoto) {
        
    }
    
    
}

extension ARCameraVC : NextLevelDeviceDelegate{
    func nextLevel(_ nextLevel: NextLevel, didChangeLensPosition lensPosition: Float) {
        
    }
    
    func nextLevelDevicePositionWillChange(_ nextLevel: NextLevel) {
        
    }
    
    func nextLevelDevicePositionDidChange(_ nextLevel: NextLevel) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didChangeDeviceOrientation deviceOrientation: NextLevelDeviceOrientation) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didChangeDeviceFormat deviceFormat: AVCaptureDevice.Format) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didChangeCleanAperture cleanAperture: CGRect) {
        
    }
    
    func nextLevelWillStartFocus(_ nextLevel: NextLevel) {
        
    }
    
    func nextLevelDidStopFocus(_ nextLevel: NextLevel) {
        
    }
    
    func nextLevelWillChangeExposure(_ nextLevel: NextLevel) {
        
    }
    
    func nextLevelDidChangeExposure(_ nextLevel: NextLevel) {
        
    }
    
    func nextLevelWillChangeWhiteBalance(_ nextLevel: NextLevel) {
        
    }
    
    func nextLevelDidChangeWhiteBalance(_ nextLevel: NextLevel) {
        
    }
    
    
}
