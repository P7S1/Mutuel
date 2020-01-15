//
//  ViewController.swift
//  Photo Editor
//
//  Created by Mohamed Hamed on 4/23/17.
//  Copyright © 2017 Mohamed Hamed. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Photos
import FirebaseAuth
import GiphyUISDK
import GiphyCoreSDK
import Kingfisher
import Lightbox
public var switchCam = Bool()

public protocol PhotoEditorDelegate {
    func imageEdited(image: UIImage)
    func editorCanceled()
    func videoEdited(video: URL)
}

public final class PhotoEditorViewController: UIViewController {
    

   
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var canvasView: UIView!
    //To hold the image
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var videoViewContainer: UIView!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var videoViewHeightConstraint: NSLayoutConstraint!
    
    // video output
    
    public var videoURL = URL(string: "")
    public var player: AVPlayer?
    public var playerController : AVPlayerViewController?
    public var output = AVPlayerItemVideoOutput()
    
    public var checkVideoOrIamge = Bool()
     var users : [Account] = [Account]()
    
    
    //To hold the drawings and stickers
    @IBOutlet weak var tempImageView: UIImageView!
    @IBOutlet weak var topToolbar: UIView!
    @IBOutlet weak var topGradient: UIView!
    @IBOutlet weak var bottomToolbar: UIView!
    @IBOutlet weak var bottomGradient: UIView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var deleteView: UIView!
    @IBOutlet weak var colorsCollectionView: UICollectionView!
    
    @IBOutlet weak var colorPickerView: UIView!
    @IBOutlet weak var colorPickerViewBottomConstraint: NSLayoutConstraint!
    
    var colorsCollectionViewDelegate: ColorsCollectionViewDelegate!
    
    public var photo: UIImage?
    public var stickers : [UIImage] = []
    
    public var photoEditorDelegate: PhotoEditorDelegate?
    //
    var bottomSheetIsVisible = false
    var drawColor: UIColor = UIColor.black
    var textColor: UIColor = UIColor.white
    var isDrawing: Bool = false
    var lastPoint: CGPoint!
    var swiped = false
    var opacity: CGFloat = 1.0
    var lastPanPoint: CGPoint?
    var lastTextViewTransform: CGAffineTransform?
    var lastTextViewTransCenter: CGPoint?
    var lastTextViewFont:UIFont?
    var activeTextView: UITextView?
    var imageRotated: Bool = false
    var imageViewToPan: UIImageView?
    
    //my custom stuff
    
    @IBOutlet weak var drawButton: UIButton!
    @IBOutlet weak var stickersButton: UIButton!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var deleteChanges: UIButton!
    @IBOutlet weak var editTextButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    
    
    //
    
    //Register Custom font before we load XIB
    public override func loadView() {
        registerFont()
        super.loadView()
    }
    
    //my custom stuff
    
    
    public override func viewDidDisappear(_ animated: Bool) {
        if let play = player {
            print("stopped")
            play.pause()
            player = nil
            print("player deallocated")
        } else {
            print("player was already deallocated")
        }
    }
    
   
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        isHeroEnabled = true
        self.hero.modalAnimationType = .selectBy(presenting:.fade, dismissing:.fade)
        deleteView.layer.addButtonShadows()
        doneButton.layer.addButtonShadows()
        drawButton.layer.addButtonShadows()
        stickersButton.layer.addButtonShadows()
        exitButton.layer.addButtonShadows()
        deleteChanges.layer.addButtonShadows()
        editTextButton.layer.addButtonShadows()
        sendButton.layer.addButtonShadows()
        saveButton.layer.addButtonShadows()
        
        topGradient.isHidden = true
        bottomGradient.isHidden = true
       /*
        if switchCam {
            videoViewContainer.transform = CGAffineTransform(scaleX: -1, y: 1)
        } else {
            videoViewContainer.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        */
        
        canvasView.layer.cornerRadius = 20
        canvasView.clipsToBounds = true
  
        if checkVideoOrIamge {

            videoViewContainer.isHidden = true
            imageView.contentMode = UIView.ContentMode.scaleAspectFit
          // tempImageView.contentMode = UIViewContentMode.scaleAspectFit
           canvasView.frame = CGRect(x: 0, y: 0, width: imageView.frame.size.width, height: imageView.frame.size.height)
           tempImageView.frame = CGRect(x: 0, y: 0, width: imageView.frame.size.width, height: imageView.frame.size.height)
            
            imageView.isHidden = false
            imageView.image = photo
            
            

           // canvasView.layer.cornerRadius = 10
          //  self.canvasView.layer.masksToBounds = true
           
            
            
        } else {
            
            videoViewContainer.isHidden = true
            imageView.isHidden = true
            
            //imageView.image = (UIImage(named: "pic")!)
     
            player = AVPlayer(url: videoURL!)
            playerController = AVPlayerViewController()
            
            guard player != nil && playerController != nil else {
                return
            }
            playerController!.showsPlaybackControls = false
            
            playerController!.player = player!
            self.addChild(playerController!)
            self.view.addSubview(playerController!.view)
           // playerController!.view.layer.cornerRadius = 10
          //  playerController!.view.layer.masksToBounds = true
          
            tempImageView.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
            
            playerController!.view.frame = view.frame
       
           view.insertSubview(playerController!.view, belowSubview: canvasView)
            NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player!.currentItem)
        
            
        }
       
        
      
        deleteView.layer.cornerRadius = deleteView.bounds.height / 2
        deleteView.layer.borderWidth = 2.0
        deleteView.layer.borderColor = UIColor.white.cgColor
        deleteView.clipsToBounds = true
        
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
        edgePan.edges = .bottom
        edgePan.delegate = self
        self.view.addGestureRecognizer(edgePan)
        

        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillChangeFrame),
                                               name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    
        
        configureCollectionView()
        bottomSheetVC = BottomSheetViewController(nibName: "BottomSheetViewController", bundle: Bundle(for: BottomSheetViewController.self))
        
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if Auth.auth().currentUser != nil {
            print("user is signed in")
        } else {
            print("user is not signed in")
            returnToLoginScreen()
        }
        
        UIView.setAnimationsEnabled(true)
        
        if checkVideoOrIamge {
            
        } else {
             player?.play()
        
        }
       
    }
    
    @objc fileprivate func playerItemDidReachEnd(_ notification: Notification) {
        if self.player != nil {
            self.player!.seek(to: CMTime.zero)
            self.player!.play()
        }
    }
    
    func configureCollectionView() {
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 30, height: 30)
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5
        colorsCollectionView.collectionViewLayout = layout
        colorsCollectionViewDelegate = ColorsCollectionViewDelegate()
        colorsCollectionViewDelegate.colorDelegate = self
        colorsCollectionView.delegate = colorsCollectionViewDelegate
        colorsCollectionView.dataSource = colorsCollectionViewDelegate
        
        colorsCollectionView.register(
            UINib(nibName: "ColorCollectionViewCell", bundle: Bundle(for: ColorCollectionViewCell.self)),
            forCellWithReuseIdentifier: "ColorCollectionViewCell")
        
    }
    
    @IBAction func saveButtonTapped(_ sender: AnyObject) {
       renderCanvas(saveToPhotoLibrary: true)
    }
    

    @IBAction func clearButtonTapped(_ sender: AnyObject) {
        //clear drawing
 
        tempImageView.image = nil
        //clear stickers and textviews
        for subview in tempImageView.subviews {
            subview.removeFromSuperview()
        }
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        view.endEditing(true)
        doneButton.isHidden = true
        colorPickerView.isHidden = true
        tempImageView.isUserInteractionEnabled = true
        hideToolbar(hide: false)
        isDrawing = false
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        doneButton.isHidden = false
        colorPickerView.isHidden = false
        hideToolbar(hide: true)
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        doneButton.isHidden = true
        hideToolbar(hide: false)
    }
    
    @objc func keyboardWillChangeFrame(_ notification: NSNotification) {
        
        if let userInfo = notification.userInfo {
            if let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue{
                if let duration:TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue{
                    
                    let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
                    let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
                    let animationCurve:UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
                    
                    if (endFrame.origin.y) >= UIScreen.main.bounds.size.height {
                        if UIDevice().userInterfaceIdiom == .phone {
                            switch UIScreen.main.nativeBounds.height {
                            case 1136:
                                print("iPhone 5 or 5S or 5C")
                                self.colorPickerViewBottomConstraint?.constant = 0.0
                            case 1334:
                                print("iPhone 6/6S/7/8")
                                self.colorPickerViewBottomConstraint?.constant = 0.0 + 15
                            case 1920, 2208:
                                print("iPhone 6+/6S+/7+/8+")
                                self.colorPickerViewBottomConstraint?.constant = 0.0
                            case 2436:
                                print("iPhone X")
                                self.colorPickerViewBottomConstraint?.constant = 0.0
                            default:
                                print("unknown")
                                self.colorPickerViewBottomConstraint?.constant = 0.0
                            }
                        }
                        
                     
                    } else {
                    
                        
                        switch UIScreen.main.nativeBounds.height {
                        case 1136:
                            print("iPhone 5 or 5S or 5C")
                            self.colorPickerViewBottomConstraint?.constant = endFrame.size.height
                        case 1334:
                            print("iPhone 6/6S/7/8")
                            self.colorPickerViewBottomConstraint?.constant = endFrame.size.height + 15
                        case 1920, 2208:
                            print("iPhone 6+/6S+/7+/8+")
                            self.colorPickerViewBottomConstraint?.constant = endFrame.size.height + 15
                        case 2436:
                            print("iPhone X")
                            self.colorPickerViewBottomConstraint?.constant = endFrame.size.height - 20
                        default:
                            print("unknown")
                            self.colorPickerViewBottomConstraint?.constant = endFrame.size.height
                        }
                        
                        
                    }
                    
                    
                    UIView.animate(withDuration: duration,
                                   delay: TimeInterval(0),
                                   options: animationCurve,
                                   animations: { self.view.layoutIfNeeded() },
                                   completion: nil)
                }
            }
        }
        
    }
    
    @objc func image(_ image: UIImage, withPotentialError error: NSErrorPointer, contextInfo: UnsafeRawPointer) {
        ProgressHUD.showSuccess("Photo Saved")
    }
    
    
    
    

    
    
    
    
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        photoEditorDelegate?.editorCanceled()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func stickersButtonTapped(_ sender: Any) {
        print("Send gif pressed")
        let giphy = GiphyViewController()
        
        giphy.layout = .waterfall
        giphy.mediaTypeConfig = [.gifs, .stickers, .text, .emoji]
        giphy.showConfirmationScreen = false
        if self.traitCollection.userInterfaceStyle == .dark {
            // User Interface is Dark
            giphy.theme = .dark
        } else {
            giphy.theme = .light
            // User Interface is Light
        }
        giphy.delegate = self
        
        self.present(giphy, animated: true, completion: nil)
       // addBottomSheetView()
    }
    
    @IBAction func textButtonTapped(_ sender: Any) {
        
        let textView = UITextView(frame: CGRect(x: 0, y: tempImageView.center.y,
                                                width: UIScreen.main.bounds.width, height: 30))
        
        //Text Attributes
        textView.textAlignment = .center
        textView.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        textView.textColor = textColor
        textView.layer.shadowColor = UIColor.black.cgColor
        textView.layer.shadowOffset = CGSize(width: 1.0, height: 0.0)
        textView.layer.shadowOpacity = 0.2
        textView.layer.shadowRadius = 1.0
        textView.layer.backgroundColor = UIColor.clear.cgColor
        //
        textView.autocorrectionType = .no
        textView.isScrollEnabled = false
        textView.delegate = self
        self.tempImageView.addSubview(textView)
        addGestures(view: textView)
        textView.becomeFirstResponder()
    }
    
    @IBAction func pencilButtonTapped(_ sender: Any) {
        isDrawing = true
        tempImageView.isUserInteractionEnabled = false
        doneButton.isHidden = false
        colorPickerView.isHidden = false
        hideToolbar(hide: true)
    }
    
    
    var bottomSheetVC: BottomSheetViewController!
    
    func addBottomSheetView() {
        bottomSheetIsVisible = true
        hideToolbar(hide: true)
        self.tempImageView.isUserInteractionEnabled = false
        bottomSheetVC.stickerDelegate = self
        
        for image in self.stickers {
            bottomSheetVC.stickers.append(image)
        }
        
       
        self.addChild(bottomSheetVC)
        self.view.addSubview(bottomSheetVC.view)
        bottomSheetVC.didMove(toParent: self)
        let height = view.frame.height
        let width  = view.frame.width
        bottomSheetVC.view.frame = CGRect(x: 0, y: self.view.frame.maxY , width: width, height: height)
    }
    
    func removeBottomSheetView() {
        bottomSheetIsVisible = false
        self.tempImageView.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       options: UIView.AnimationOptions.curveEaseIn,
                       animations: { () -> Void in
                        var frame = self.bottomSheetVC.view.frame
                        frame.origin.y = UIScreen.main.bounds.maxY
                        self.bottomSheetVC.view.frame = frame
                        
        }, completion: { (finished) -> Void in
            self.bottomSheetVC.view.removeFromSuperview()
            self.bottomSheetVC.removeFromParent()
            self.hideToolbar(hide: false)
        })
    }
    
    func hideToolbar(hide: Bool) {
        topToolbar.isHidden = hide
        bottomToolbar.isHidden = hide
     
    }
    
    private func getImageLayer(height: CGFloat) -> CALayer {
        let imglogo = UIImage(named: "bird_1.png")
        
        let imglayer = CALayer()
        imglayer.contents = imglogo?.cgImage
        imglayer.frame = CGRect(
            x: 0, y: height - imglogo!.size.height/4,
            width: imglogo!.size.width/4, height: imglogo!.size.height/4)
        imglayer.opacity = 0.6
        
        return imglayer
    }
    

//
//    // Mark :- save a video photoLibrary
    func convertVideoAndSaveTophotoLibrary(videoURL: URL, saveToPhotoLibray : Bool) {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let myDocumentPath = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("temp.mp4").absoluteString
        _ = NSURL(fileURLWithPath: myDocumentPath)
        let documentsDirectory2 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        let filePath = documentsDirectory2.appendingPathComponent("video.mp4")
        deleteFile(filePath: filePath as NSURL)

        //Check if the file already exists then remove the previous file
        if FileManager.default.fileExists(atPath: myDocumentPath) {
            do { try FileManager.default.removeItem(atPath: myDocumentPath)
            } catch let error { print(error) }
        }

        // File to composit
        let asset = AVURLAsset(url: videoURL as URL)
        var gifs = [GPHMediaView]()
            for subview in self.tempImageView.subviews{
                if subview is GPHMediaView{
                let gifView = subview as! GPHMediaView
                    gifs.append(gifView)
                    /*
                let gifURL = URL(string: (gifView.media?.url(rendition: .original, fileType: .gif))!)!
            //    let image = LightboxImage(image: UIImage(named: "group")!, text: "test", videoURL: gifURL)
             //   self.presentLightBoxController(images: [image], goToIndex: nil)
                let tempUrl = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent("gif.mp4")
                
                let data = try! Data(contentsOf: gifURL)
                    let dispatchGroup = DispatchGroup()
                        dispatchGroup.enter()
                    DispatchQueue.global().async{
                GIF2MP4(data: data )?.convertAndExport(to: tempUrl, completion: {
                    let gifAsset = AVURLAsset(url: tempUrl)
                    let gifTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
                    var failed = false
                   do{
                        try gifTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: gifAsset.duration), of: gifAsset.tracks(withMediaType: AVMediaType.video)[0], at: CMTime.zero)
                    }
                    catch{
                        failed = true
                        print("failed to add third track dick")
                    }
                    if !failed{
                        print("succeeded to add tracks dick")
                        tracks.append(gifTrack)
                        assets.append(gifAsset)
                        gifs.append(gifView)
        
                    }
                    dispatchGroup.leave()
                })
                    }
                    dispatchGroup.wait() */
                   // let item = LightboxImage(image: UIImage(named: "group")!, text: "bitch", videoURL: tempUrl)
                   // self.presentLightBoxController(images: [item], goToIndex: nil)
            }
        }
        print("dispatch group dick")
        let clipVideoTrack = asset.tracks(withMediaType: AVMediaType.video)[0]


        // Rotate to potrait
       let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack)
       
        let videoTransform:CGAffineTransform = clipVideoTrack.preferredTransform


        
        //fix orientation
        var videoAssetOrientation_  = UIImage.Orientation.right
        
        var isVideoAssetPortrait_  = false
        
        var text = "none"
        
        if videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0 {
            videoAssetOrientation_ = UIImage.Orientation.right
            isVideoAssetPortrait_ = true
            text = "right"
        }
        if videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == 1.0 && videoTransform.d == 0 {
            videoAssetOrientation_ = UIImage.Orientation.right
            isVideoAssetPortrait_ = true
            text = "special"
            print("this bitch is special :)")
        }
        if videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0 {
            videoAssetOrientation_ =  UIImage.Orientation.left
            isVideoAssetPortrait_ = true
            text = "left"
        }
        if videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0 {
            videoAssetOrientation_ =  UIImage.Orientation.up
            text = "up)"
        }
        if videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0 {
            videoAssetOrientation_ = UIImage.Orientation.down;
            text = "down"
        }
        
        print("width: \(clipVideoTrack.naturalSize.width),height:\(clipVideoTrack.naturalSize.height)")
        if text == "special"{
            print(clipVideoTrack.preferredTransform)
            let transform = CGAffineTransform(a: 0, b: 1, c: 1, d: 0, tx: 00, ty: 0)
            transformer.setTransform(transform.translatedBy(x: 0, y: 0), at: CMTime.zero)
            
        }else{
            print(clipVideoTrack.preferredTransform)
            transformer.setTransform(clipVideoTrack.preferredTransform, at: CMTime.zero)
        }
        print("width: \(clipVideoTrack.naturalSize.width),height:\(clipVideoTrack.naturalSize.height)")
        print("SIZES: \(videoTransform.a),\(videoTransform.b),\(videoTransform.c),\(videoTransform.tx),\(videoTransform.d),\(videoTransform.ty),")
        print("VIdeo Asset Oreintation: \(text)")
       transformer.setOpacity(0.0, at: asset.duration)
        

        //adjust the render size if neccessary
       var naturalSize: CGSize
        if(isVideoAssetPortrait_){
            naturalSize = CGSize(width: clipVideoTrack.naturalSize.height, height: clipVideoTrack.naturalSize.width)
        } else {
            naturalSize = clipVideoTrack.naturalSize;
        }
    
        var renderWidth: CGFloat!
        var renderHeight: CGFloat!
        renderWidth = naturalSize.width
        renderHeight = naturalSize.height
        let renderSize =  CGSize(width: renderWidth, height: renderHeight)


        let parentlayer = CALayer()
        let videoLayer = CALayer()
        let watermarkLayer = CALayer()


        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        videoComposition.renderScale = 1.0
        
        
        watermarkLayer.contents = tempImageView.asImage().cgImage
        parentlayer.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: naturalSize)
        videoLayer.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: naturalSize)
        
        parentlayer.addSublayer(videoLayer)
        watermarkLayer.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: naturalSize)
        let gifLayer = CALayer()
        parentlayer.addSublayer(watermarkLayer)
        gifLayer.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: tempImageView.frame.size)
        
        for gif in gifs{
        let miniGifLayer = CALayer()
        let animation = VideoHelper.createGIFAnimation(url: URL(string: (gif.media?.url(rendition: .original, fileType: .gif))!)!)
    miniGifLayer.add(animation!, forKey: "test")
      /*     let ratio = gif.media?.aspectRatio
            let goalFrame = CGRect(origin: gif.frame.origin, size: CGSize(width: 150, height: 150))
            let size = VideoHelper.getSuitableSize(goalFrame: goalFrame.size, ratio: ratio!)
            miniGifLayer.frame = CGRect(origin: CGPoint(x: gif.frame.origin.x, y:(tempImageView.frame.height-size.height)-(gif.frame.origin.y)), size: size)
            miniGifLayer.setAffineTransform(gif.transform)
            print("before y origin\(gif.frame.origin.y)")
            print("after y origin \(tempImageView.frame.height-(gif.frame.origin.y))")
            //miniGifLayer.center = gif.center */
            let frame = CGRect(x: gif.frame.origin.x, y: (tempImageView.frame.height-gif.frame.height)-(gif.frame.origin.y), width: gif.frame.width, height: gif.frame.height)
            miniGifLayer.frame = gif.frame
            miniGifLayer.frame.origin = gif.frame.origin
            miniGifLayer.transform = gif.layer.transform
            gifLayer.addSublayer(miniGifLayer)
        }
        let rectangle = CGRect(origin: CGPoint(x: 0, y: 0), size: naturalSize)
        let transform = VideoHelper.transformFromRect(from: gifLayer.frame, toRect: rectangle)
        gifLayer.setAffineTransform(transform)
        parentlayer.addSublayer(gifLayer)
        // Add watermark to video
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayers: [videoLayer], in: parentlayer)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: CMTimeMakeWithSeconds(60, preferredTimescale: 30))
        instruction.backgroundColor = .none
        instruction.layerInstructions = [transformer]
        
        videoComposition.instructions = [instruction]
        let exporter = AVAssetExportSession.init(asset: asset, presetName: AVAssetExportPresetMediumQuality)
        exporter?.outputFileType = AVFileType.mov
        exporter?.outputURL = filePath
        exporter?.videoComposition = videoComposition

        exporter!.exportAsynchronously(completionHandler: {() -> Void in
            if exporter?.status == .completed {
                if ((exporter?.outputURL) != nil) && saveToPhotoLibray{
                    self.saveToPhotoLibrary(outputURL: exporter!.outputURL!)
                }else if ((exporter?.outputURL) != nil) && !saveToPhotoLibray{
                    ProgressHUD.dismiss()
                    DispatchQueue.main.async{
                        let image = FollowersHelper().generateThumbnail(path: exporter!.outputURL!)
                        self.presentSendToUserViewController(image: image, video: exporter!.outputURL!, size: clipVideoTrack.naturalSize)
                    }
                    self.photoEditorDelegate?.videoEdited(video: exporter!.outputURL!)
                }
            }
        })


    }
    
    func saveToPhotoLibrary(outputURL : URL){
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
        }) { saved, error in
            if saved {
                ProgressHUD.showSuccess("Video Saved")
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions).lastObject
                PHImageManager().requestAVAsset(forVideo: fetchResult!, options: nil, resultHandler: { (avurlAsset, audioMix, dict) in
                    let newObj = avurlAsset as! AVURLAsset
                    print(newObj.url)
                    DispatchQueue.main.async(execute: {
                        print(newObj.url.absoluteString)
                    })
                })
                print (fetchResult!)
            }
        }
    }
   
    
    
  
    
    func deleteFile(filePath:NSURL) {
        guard FileManager.default.fileExists(atPath: filePath.path!) else {
            return
        }
        
        do { try FileManager.default.removeItem(atPath: filePath.path!)
        } catch { fatalError("Unable to delete file: \(error)") }
    }
    
    
    func renderCanvas(saveToPhotoLibrary : Bool){
        ProgressHUD.show()
                if checkVideoOrIamge {
                    var isGifImage = false
                    var duration : TimeInterval = 0.0
                    for subview in tempImageView.subviews{
                        if subview is GPHMediaView{
                            let gif = subview as! GPHMediaView
                            if gif.animationDuration > duration{
                                duration = gif.animationDuration
                            }
                            isGifImage = true
                        }
                    }
                    if isGifImage{
                        
                    }else{
                        let imageFrame = VideoHelper.calculateRectOfImageInImageView(imageView: imageView)
                        let exportedImage = canvasView.toImage().croppedImage(withFrame: imageFrame, angle: 0, circularClip: false)
                        if saveToPhotoLibrary{
                    UIImageWriteToSavedPhotosAlbum(exportedImage,self, #selector(PhotoEditorViewController.image(_:withPotentialError:contextInfo:)), nil)
                        }else{
                            ProgressHUD.dismiss()
                            presentSendToUserViewController(image: exportedImage, video: nil, size : imageFrame.size)
                            photoEditorDelegate?.imageEdited(image: exportedImage)
                        }
                    }
                } else {
                    convertVideoAndSaveTophotoLibrary(videoURL: videoURL!, saveToPhotoLibray: saveToPhotoLibrary)
                }
    }
    
   @IBAction func continueButtonPressed(_ sender: Any) {
    print("continue button pressed")
        renderCanvas(saveToPhotoLibrary: false)
    }
    
    
    
}
 
 

extension PhotoEditorViewController: ColorDelegate {
    func chosedColor(color: UIColor) {
        if isDrawing {
            self.drawColor = color
        } else if activeTextView != nil {
            activeTextView?.textColor = color
            textColor = color
        }
    }
}

extension PhotoEditorViewController: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        let rotation = atan2(textView.transform.b, textView.transform.a)
        if rotation == 0 {
            let oldFrame = textView.frame
            let sizeToFit = textView.sizeThatFits(CGSize(width: oldFrame.width, height:CGFloat.greatestFiniteMagnitude))
            textView.frame.size = CGSize(width: oldFrame.width, height: sizeToFit.height)
        }
    }
    public func textViewDidBeginEditing(_ textView: UITextView) {
        lastTextViewTransform =  textView.transform
        lastTextViewTransCenter = textView.center
        lastTextViewFont = textView.font!
        activeTextView = textView
        textView.superview?.bringSubviewToFront(textView)
        textView.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        UIView.animate(withDuration: 0.3,
                       animations: {
                        textView.transform = CGAffineTransform.identity
                        textView.center = CGPoint(x: UIScreen.main.bounds.width / 2, y: 100)
        }, completion: nil)
        
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        guard lastTextViewTransform != nil && lastTextViewTransCenter != nil && lastTextViewFont != nil
            else {
                return
        }
        activeTextView = nil
        textView.font = self.lastTextViewFont!
        UIView.animate(withDuration: 0.3,
                       animations: {
                        textView.transform = self.lastTextViewTransform!
                        textView.center = self.lastTextViewTransCenter!
        }, completion: nil)
    }
    
}

extension PhotoEditorViewController: StickerDelegate {
    
    func viewTapped(view: UIView) {
        self.removeBottomSheetView()
        view.center = tempImageView.center
        
        self.tempImageView.addSubview(view)
        //Gestures
        addGestures(view: view)
    }
    
    func imageTapped(image: UIImage) {
        self.removeBottomSheetView()
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame.size = CGSize(width: 150, height: 150)
        imageView.center = tempImageView.center
        
        self.tempImageView.addSubview(imageView)
        //Gestures
        addGestures(view: imageView)
    }
    
    func bottomSheetDidDisappear() {
        
        bottomSheetIsVisible = false
        hideToolbar(hide: false)
    }
    
    func addGestures(view: UIView) {
        //Gestures
        view.isUserInteractionEnabled = true
        
        let panGesture = UIPanGestureRecognizer(target: self,
                                                action: #selector(PhotoEditorViewController.panGesture))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self,
                                                    action: #selector(PhotoEditorViewController.pinchGesture))
        pinchGesture.delegate = self
        view.addGestureRecognizer(pinchGesture)
        
        let rotationGestureRecognizer = UIRotationGestureRecognizer(target: self,
                                                                    action:#selector(PhotoEditorViewController.rotationGesture) )
        rotationGestureRecognizer.delegate = self
        view.addGestureRecognizer(rotationGestureRecognizer)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(PhotoEditorViewController.tapGesture))
        view.addGestureRecognizer(tapGesture)
        
    }
}

extension PhotoEditorViewController {
    
    //Resources don't load in main bundle we have to register the font
    func registerFont(){
        let bundle = Bundle(for: PhotoEditorViewController.self)
        let url =  bundle.url(forResource: "Eventtus-Icons", withExtension: "ttf")
        
        guard let fontDataProvider = CGDataProvider(url: url! as CFURL) else {
            return
        }
        let font = CGFont(fontDataProvider)
        var error: Unmanaged<CFError>?
        guard CTFontManagerRegisterGraphicsFont(font!, &error) else {
            return
        }
    }
    
    func presentSendToUserViewController(image : UIImage?, video : URL?, size : CGSize){
       let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SendToUserViewController") as! SendToUserViewController
        vc.selectedUsers = users
        vc.video = video
        vc.size = size
        if let img = image{
            vc.image = img
        }
        present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
}

extension PhotoEditorViewController: GiphyDelegate {
    public func didSelectMedia(giphyViewController: GiphyViewController, media: GPHMedia) {
        
        let imageView = GPHMediaView()
        imageView.setMedia(media)
        let ratio = media.aspectRatio
            imageView.contentMode = .scaleAspectFit
        
        let goalFrame = CGRect(x: 0, y: 0, width: 150, height: 150)
        
        let size = VideoHelper.getSuitableSize(goalFrame: goalFrame.size, ratio: ratio)
        imageView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
            imageView.center = self.tempImageView.center
            self.tempImageView.addSubview(imageView)
            //Gestures
            self.addGestures(view: imageView)
            giphyViewController.dismiss(animated: true, completion: nil)
        
    }
    
    public func didDismiss(controller: GiphyViewController?) {
        print("did dismiss")
    }

    
    
}

