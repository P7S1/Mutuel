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
import VideoToolbox
import FirebaseAuth
var _nextLevel: NextLevel?
var _bufferRenderer: NextLevelBufferRenderer?
class ARCameraVC: UIViewController {
    
    var flashEnabled = false
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var searchResultsView: UICollectionView!
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    @IBOutlet weak var captureButton : RecordingButton!
    
    var cameraDelegate : CameraDelegate?
    
    
    var searchResults: [SvrfMedia] = []
    let contentUpdater = VirtualContentUpdater()
    let remoteFaceFilter = RemoteFaceFilter()
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Auth.auth().currentUser != nil {
            print("user is signed in")
        } else {
            returnToLoginScreen()
            print("user is not signed in")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _bufferRenderer = NextLevelBufferRenderer(view: self.sceneView)
        startCamera()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ProgressHUD.dismiss()
        _nextLevel?.stop()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        searchResultsView.delegate = self
        searchResultsView.dataSource = self
        searchBar.addDoneButtonOnKeyboard()
        // ContentUpdater will tell the A)RSCNView what to draw
        sceneView.delegate = contentUpdater
        sceneView.session.delegate = contentUpdater

        // ContentUpdater's virtual face node will dictate what Face Filter to render
        contentUpdater.virtualFaceNode = remoteFaceFilter
    
        setButtonShadows()
        setupCamera()
        
        searchBar.delegate = self
        
        captureButton.delegate = self
        let captureTap = UITapGestureRecognizer(target: self, action: #selector(takePhoto))
        captureButton.addGestureRecognizer(captureTap)
        
        let videoPress = UILongPressGestureRecognizer(target: self, action: #selector(startRecording))
        captureButton.addGestureRecognizer(videoPress)
        
        
        getTrendingFilters()
    }
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    @IBAction func goBackButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func takePhoto(){
        _nextLevel?.capturePhotoFromVideo()
        print("photo button tapped")
    }
    
    @objc func startRecording(sender : UILongPressGestureRecognizer){
        switch sender.state {
        case .began:
            print("video started recording")
            _nextLevel?.record()
          //  captureButton.record()
            //start recording
        case .ended:
            print("video paused")

            
          //  self.captureButton.stopRecord()
                self.stopRecording()
            
        default:
            break
        }
    }

    func stopRecording(){
        if let session = _nextLevel?.session {
            // export
            
            session.endClip { (clip, error) in
                if error == nil{
                    session.mergeClips(usingPreset: AVAssetExportPreset960x540, completionHandler: { (url: URL?, error: Error?) in
                       if let videoUrl = url {
                           self.saveVideo(url: videoUrl)
                       } else if let err = error {
                           print("Exporting error: \(err.localizedDescription)")
                           //
                       }
                    })
                }else{
                    print("ther was an error : \(error!)")
                }
            }

            //..
        }
    }
    
    func setButtonShadows(){
        captureButton.layer.addButtonShadows()
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
    
    func startCamera(){
        // setup tracking
        let arConfig = ARFaceTrackingConfiguration()
        if #available(iOS 13.0, *) {
            arConfig.maximumNumberOfTrackedFaces = 3
        }
        arConfig.providesAudioData = true
        arConfig.isLightEstimationEnabled = true
       
            _nextLevel?.arConfiguration?.session = self.sceneView.session
            _nextLevel?.arConfiguration?.config = arConfig
            _nextLevel?.arConfiguration?.runOptions = []
        
        // run session
        do {
            try _nextLevel?.start()
        } catch let error {
            print("failed to start camera \(error)")
        }
    }

 func setupCamera() {
    // setup physical camera, NextLevel
    _nextLevel = NextLevel()
    if let nextLevel = _nextLevel {
       //nextLevel.previewLayer.frame = self.sceneView.frame
        
        nextLevel.delegate = self
        nextLevel.videoDelegate = self
        nextLevel.deviceDelegate = self
        nextLevel.videoDelegate = self
        
        nextLevel.captureMode = .arKit
        nextLevel.isVideoCustomContextRenderingEnabled = true
        nextLevel.videoStabilizationMode = .off
        nextLevel.frameRate = 60
        
   /*     //video configur ation
        nextLevel.videoConfiguration.maximumCaptureDuration = CMTime(seconds: 12.0, preferredTimescale: 1)
        nextLevel.videoConfiguration.bitRate = 15000000
        nextLevel.videoConfiguration.maxKeyFrameInterval = 30
        nextLevel.videoConfiguration.scalingMode = AVVideoScalingModeResizeAspect
        nextLevel.videoConfiguration.codec = AVVideoCodecType.hevc
        nextLevel.videoConfiguration.profileLevel = String(kVTProfileLevel_HEVC_Main_AutoLevel)
        // audio configuration
        nextLevel.audioConfiguration.bitRate = 96000 */
        
        
    }
    
}
    
    func saveVideo(url :URL){
        cameraDelegate?.didFinishProcessingVideo(url: url)
    }
    
    func savePhoto(photo : UIImage){
        cameraDelegate?.didTakePhoto(image: photo)
    }
}

extension ARCameraVC : NextLevelVideoDelegate{
    func nextLevel(_ nextLevel: NextLevel, didUpdateVideoZoomFactor videoZoomFactor: Float) {
        
    }
    
    
    
    func nextLevel(_ nextLevel: NextLevel, willProcessRawVideoSampleBuffer sampleBuffer: CMSampleBuffer, onQueue queue: DispatchQueue) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, renderToCustomContextWithImageBuffer imageBuffer: CVPixelBuffer, onQueue queue: DispatchQueue) {
        if let frame = _bufferRenderer?.videoBufferOutput {
                   nextLevel.videoCustomContextImageBuffer = frame
               }
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
        print("did complete clip")
       // stopRecording()
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
        print("did complete session")
        self.stopRecording()
    }
    
    func nextLevel(_ nextLevel: NextLevel, didCompletePhotoCaptureFromVideoFrame photoDict: [String : Any]?) {
        print("did complete photo capture from video frame")
        if let dictionary = photoDict,
            let photoData = dictionary[NextLevelPhotoJPEGKey] as? Data,
            let photoImage = UIImage(data: photoData) {
            savePhoto(photo: photoImage)
        }else{
            print("photo image to UIImage error")
        }
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

extension ARCameraVC : ARSessionObserver{
    public func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        #if PROTOTYPE
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        // Use `flatMap(_:)` to remove optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        DispatchQueue.main.async {
            TinyConsole.print("session error, \(errorMessage)")
        }
        #endif
        startCamera()
    }
    
    public func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
    }
    
    public func sessionWasInterrupted(_ session: ARSession) {
        _nextLevel?.handleSessionWasInterrupted(Notification(name: Notification.Name("NextLevel")))
    }
    
    public func sessionInterruptionEnded(_ session: ARSession) {
        _nextLevel?.handleSessionInterruptionEnded(Notification(name: Notification.Name("NextLevel")))
    }
    
    public func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
    public func session(_ session: ARSession, didOutputAudioSampleBuffer audioSampleBuffer: CMSampleBuffer) {
        _nextLevel?.arSession(session, didOutputAudioSampleBuffer: audioSampleBuffer)
    }
}


extension ARCameraVC : RecordingButtonDelegate{
    func didStartCapture() {
        print("did start captre")
    }
    
    func didEndCapture() {
        print("did end capture")
    }
    
    
}
