//
//  CameraVC.swift
//  PhotoVideoEditor
//
//  Created by Faris Albalawi on 11/12/18.
//  Copyright © 2018 Faris Albalawi. All rights reserved.
//

import UIKit
import AVFoundation
import FirebaseAuth
import GiphyUISDK
import GiphyCoreSDK
import ARKit
protocol CameraDelegate {
    func didFinishProcessingVideo(url : URL)
    func didTakePhoto(image : UIImage)
}
class CameraVC: SwiftyCamViewController, SwiftyCamViewControllerDelegate {
    
    @IBOutlet weak var captureButton: RecordingButton!
    @IBOutlet weak var flipCameraButton : UIButton!
    @IBOutlet weak var flashButton      : UIButton!
    @IBOutlet weak var arCameraButton: UIButton!
    
    var initialZoom : CGFloat = 1
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    var cameraVCDelegate : CameraDelegate?
    
    override func viewDidLoad() {
        videoGravity = .resizeAspectFill
        super.viewDidLoad()
        captureButton.delegate = self
        shouldPrompToAppSettings = true
        cameraDelegate = self
        maximumVideoDuration = 15.0
        shouldUseDeviceOrientation = false
        allowAutoRotate = false
        audioEnabled = true
        allowBackgroundAudio = true
        self.swipeToZoom = false
        
        self.videoQuality = .iframe960x540
        
        
        captureButton.layer.addButtonShadows()
        flipCameraButton.layer.addButtonShadows()
        flashButton.layer.addButtonShadows()
        arCameraButton.layer.addButtonShadows()
        
        let captureTap = UITapGestureRecognizer(target: self, action: #selector(takeAPhoto))
        captureButton.addGestureRecognizer(captureTap)
        
        let videoPress = UILongPressGestureRecognizer(target: self, action: #selector(startRecording))
        captureButton.addGestureRecognizer(videoPress)
        
        // disable capture button until session starts
        let zoom = UIPanGestureRecognizer(target: self, action: #selector(zoomGesture))
        
        if !ARFaceTrackingConfiguration.isSupported{
            arCameraButton.isHidden = true
        }
        //captureButton.addGestureRecognizer(zoom)
        captureButton.isEnabled = false
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if Auth.auth().currentUser != nil {
            print("user is signed in")
        } else {
            print("user is not signed in")
            returnToLoginScreen() 
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    override func viewWillAppear(_ animated : Bool){
        super.viewWillAppear(animated)
        showButtons()
        UIView.animate(withDuration : 0.2){
            self.captureButton.alpha = 1
        }
    }
    
    @IBAction func dismissPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
   
    @IBAction func presentAR(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ARCameraVC") as! ARCameraVC
        vc.isHeroEnabled = true
        vc.hero.modalAnimationType = .selectBy(presenting:.zoom, dismissing:.zoomOut)
        vc.modalPresentationStyle = .fullScreen
        vc.cameraDelegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func takeAPhoto(){
        takePhoto()
        UIView.animate(withDuration : 0.2){
            self.captureButton.alpha = 0
        }
        hideButtons()
    }
    
    @objc func startRecording(sender : UILongPressGestureRecognizer){
       switch sender.state {
        case .began:
            startVideoRecording()
        case .ended,.failed:
            stopVideoRecording()
        default:
            break
        }
    }
    
    
    func swiftyCamSessionDidStartRunning(_ swiftyCam: SwiftyCamViewController) {
        print("Session did start running")
        //ProgressHUD.dismiss()
        captureButton.isEnabled = true
    }
    
    func swiftyCamSessionDidStopRunning(_ swiftyCam: SwiftyCamViewController) {
        print("Session did stop running")
        captureButton.isEnabled = false
    }
    
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didTake photo: UIImage) {
        
        //        let newVC = PhotoViewController(image: photo)
        //        self.present(newVC, animated: true, completion: nil)
        //
     /*   let storyboard = UIStoryboard(name: "PhotoEditor", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PhotoEditorViewController") as! PhotoEditorViewController
        vc.photo = photo
        vc.checkVideoOrIamge = true
        
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil) */
        
        cameraVCDelegate?.didTakePhoto(image: photo)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didBeginRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        print("Did Begin Recording")
        captureButton.record()
        hideButtons()
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        print("Did finish Recording")
        captureButton.stopRecord()
        showButtons()
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
        
        cameraVCDelegate?.didFinishProcessingVideo(url: url)
        
        /*
        let storyboard = UIStoryboard(name: "PhotoEditor", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PhotoEditorViewController") as! PhotoEditorViewController
        vc.videoURL = url
        vc.checkVideoOrIamge = false
        vc.modalPresentationStyle = .fullScreen
        
        present(vc, animated: true, completion: nil) */
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFocusAtPoint point: CGPoint) {
        print("Did focus at point: \(point)")
        focusAnimationAt(point)
    }
    
    func swiftyCamDidFailToConfigure(_ swiftyCam: SwiftyCamViewController) {
        let message = NSLocalizedString("Unable to capture media", comment: "Alert message when something goes wrong during capture session configuration")
        let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = self.view.frame
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didChangeZoomLevel zoom: CGFloat) {
        print("Zoom level did change. Level: \(zoom)")
        print(zoom)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didSwitchCameras camera: SwiftyCamViewController.CameraSelection) {
        print("Camera did change to \(camera.rawValue)")
        print(camera)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFailToRecordVideo error: Error) {
        print(error)
    }
    
    @IBAction func cameraSwitchTapped(_ sender: Any) {
        switchCamera()
    }
    
    @IBAction func toggleFlashTapped(_ sender: Any) {
        flashEnabled = !flashEnabled
        toggleFlashAnimation()
    }
}


// UI Animations
extension CameraVC {
    
    fileprivate func hideButtons() {
        UIView.animate(withDuration: 0.25) {
            self.flashButton.alpha = 0.0
            self.flipCameraButton.alpha = 0.0
            self.arCameraButton.alpha = 0.00
        }
    }
    
    fileprivate func showButtons() {
        UIView.animate(withDuration: 0.25) {
            self.flashButton.alpha = 1.0
            self.flipCameraButton.alpha = 1.0
            self.arCameraButton.alpha = 1.0
        }
    }
    
    fileprivate func focusAnimationAt(_ point: CGPoint) {
        let focusView = UIImageView(image: #imageLiteral(resourceName: "focus"))
        focusView.center = point
        focusView.alpha = 0.0
        view.addSubview(focusView)
        
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            focusView.alpha = 1.0
            focusView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        }) { (success) in
            UIView.animate(withDuration: 0.15, delay: 0.5, options: .curveEaseInOut, animations: {
                focusView.alpha = 0.0
                focusView.transform = CGAffineTransform(translationX: 0.6, y: 0.6)
            }) { (success) in
                focusView.removeFromSuperview()
            }
        }
    }
    
    fileprivate func toggleFlashAnimation() {
        if flashEnabled == true {
            flashButton.setImage(UIImage(systemName: "bolt.fill"), for: UIControl.State())
        } else {
            flashButton.setImage(UIImage(systemName: "bolt.slash.fill"), for: UIControl.State())
        }
    }
}


extension CameraVC{
    @objc func zoomGesture(_ sender: UIPanGestureRecognizer) {

        // note that 'view' here is the overall video preview
        let velocity = sender.velocity(in: view)

        if velocity.y > 0 || velocity.y < 0 {

           let originalCapSession = session
           var devitce : AVCaptureDevice!

           let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDuoCamera], mediaType: AVMediaType.video, position: .unspecified)
           let devices = videoDeviceDiscoverySession.devices
           devitce = devices.first!

           guard let device = devitce else { return }

            let minimumZoomFactor: CGFloat = 1.0
            let maximumZoomFactor: CGFloat = min(device.activeFormat.videoMaxZoomFactor, 10.0) // artificially set a max useable zoom of 10x

            // clamp a zoom factor between minimumZoom and maximumZoom
            func clampZoomFactor(_ factor: CGFloat) -> CGFloat {
                return min(max(factor, minimumZoomFactor), maximumZoomFactor)
            }

            func update(scale factor: CGFloat) {
                do {

                    try device.lockForConfiguration()
                    defer { device.unlockForConfiguration() }
                    device.videoZoomFactor = factor
                } catch {
                    print("\(error.localizedDescription)")
                }
            }

            switch sender.state {

            case .began:
                initialZoom = device.videoZoomFactor
                //startRecording() /// call to start recording your video

            case .changed:

                // distance in points for the full zoom range (e.g. min to max), could be view.frame.height
                let fullRangeDistancePoints: CGFloat = 300.0

                // extract current distance travelled, from gesture start
                let currentYTranslation: CGFloat = sender.translation(in: view).y

                // calculate a normalized zoom factor between [-1,1], where up is positive (ie zooming in)
                let normalizedZoomFactor = -1 * max(-1,min(1,currentYTranslation / fullRangeDistancePoints))

                // calculate effective zoom scale to use
                let newZoomFactor = clampZoomFactor(initialZoom + normalizedZoomFactor * (maximumZoomFactor - minimumZoomFactor))

                // update device's zoom factor'
                update(scale: newZoomFactor)

            case .ended, .cancelled:
              //  stopRecording() /// call to start recording your video
                break

            default:
                break
            }
        }
    }
}

extension CameraVC : RecordingButtonDelegate{
    func didStartCapture() {
        print("did start capture")
    }
    
    func didEndCapture() {
        print("did end capture")
    }
    
    
}

extension CameraVC : CameraDelegate{
    func didFinishProcessingVideo(url: URL) {
        cameraVCDelegate?.didFinishProcessingVideo(url: url)
    }
    
    func didTakePhoto(image: UIImage) {
        cameraVCDelegate?.didTakePhoto(image: image)
    }
    
    
}
