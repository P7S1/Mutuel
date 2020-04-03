//
//  SendToUserViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 12/22/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import FirebaseStorage
import AVFoundation
import SkeletonView
import GiphyCoreSDK
import Lightbox
import CollectionViewWaterfallLayout
import Kingfisher
import StoreKit
class SendToUserViewController: UIViewController {
    var video : URL?
    var image = UIImage()
    var photoSize : CGSize!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var playButton: UIImageView!
    let sendButton = UIButton.init(type: .custom)
    
    var isGIF = false
    
    var media = GPHMedia()
    @IBOutlet weak var challengeLabel: UILabel!
    
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    
    var challenge : Challenge?
    
    var challengeDay : ChallengeDay?
    
    var tags : [String] = [String]()

    
    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        
        textView.delegate = self
        navigationItem.title = "Share"
       //  setDismissButton()
        addImageShadow()
        if isGIF{
            if let gifString = media.url(rendition: .fixedWidth, fileType: .gif), let gifURL = URL(string: gifString) {
                imageView.kf.setImage(with: gifURL)
                photoSize = CGSize(width: 400, height: 400 * (1/media.aspectRatio))
                
                for tag in media.tags ?? [String](){
                    if self.tags.count<6{
                        self.tags.append(tag)
                    }
                }
                calculateSize()
            } else{
             self.dismiss(animated: true, completion: nil)
            }
        }else{
            imageView.image = image
            calculateSize()
        }
        // Do any additional setup after loading the view.

        textView.addDoneButtonOnKeyboard()
        textView.text = "Write a caption..."
        textView.textColor = UIColor.secondaryLabel
        textView.backgroundColor = UIColor.secondarySystemBackground
        textView.clipsToBounds = true
        textView.layer.cornerRadius = 10
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        setUpSendButton()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(photoPressed))
        
        containerView.addGestureRecognizer(tap)
        
        challengeLabel.text = challengeDay?.activity ?? ""
        
        playButton.isHidden = video == nil
        
        setUpCollectionView()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        sendButton.isEnabled = true
    }
    
    func calculateSize(){
        UIView.animate(withDuration: 0.2) {
            let scale = self.containerView.frame.height / self.photoSize.height
            var width : CGFloat = self.photoSize.width * scale
            
            if width >= self.view.frame.width - 32{
            width = self.view.frame.width - 32
            }
            self.widthConstraint.constant = width
        }
    }
    
    func addImageShadow(){
        containerView.layer.cornerRadius = 10.0
        containerView.layer.shadowColor = UIColor.darkGray.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        containerView.layer.shadowRadius = 12.0
        containerView.layer.shadowOpacity = 0.6
        
        
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10.0
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    @objc func photoPressed(){
        
        
        if self.isGIF{
            
        if let gifString = media.url(rendition: .fixedWidth, fileType: .gif), let gifURL = URL(string: gifString) {
        let image = LightboxImage(imageURL: gifURL, text: textView.text, videoURL: nil)
        self.presentLightBoxController(images: [image], goToIndex: nil)
            }
        }else{
        let image = LightboxImage(image: self.image, text: textView.text, videoURL: self.video)
        self.presentLightBoxController(images: [image], goToIndex: nil)
        }

    }
    

    
    @objc func sendPressed(){
        
        print("send pressed")
        
        if tags.isEmpty{
            ProgressHUD.showError("You must select atleast one tag")
        }else{
        sendButton.isEnabled = false
        ProgressHUD.show("Posting")
        
        if isGIF{
            if let gifString = media.url(rendition: .fixedWidth, fileType: .gif), let gifURL = URL(string: gifString){
                self.saveToDatabase(photoURL: gifURL, videoURL: nil, isVideo: false, storageRef: "", videoStorageRef: "")
            }else{
                self.dismiss(animated: true, completion: nil)
                ProgressHUD.showError("Error")
            }
        }else{
            postMedia(isVideo: false) { (photoURL, storageRef) in
                if self.video != nil{
                    self.postMedia(isVideo: true) { (videoURL, videoStorageRef) in
                        self.saveToDatabase(photoURL: photoURL, videoURL: videoURL, isVideo: true, storageRef: storageRef,videoStorageRef: videoStorageRef)
                    }
                }else{
                    self.saveToDatabase(photoURL: photoURL, videoURL: nil, isVideo: false, storageRef: storageRef, videoStorageRef: storageRef)
                }
            }
        }
        
            self.view.window!.rootViewController?.dismiss(animated: true, completion: {
                SKStoreReviewController.requestReview()
            })
        }
    }
    
    
    func postMedia(isVideo : Bool, completion: @escaping (URL,String) -> Void){
        var data0 = Data()
        var dataExtension = ".jpg"
        if !(isVideo){
            data0 = image.jpegData(compressionQuality: 0.6) ?? Data()
        }else{
            do {
                try data0 = NSData(contentsOf: video!) as Data
            } catch {
                ProgressHUD.showError("error")
                print(error)
            }
            dataExtension = ".mp4"
        }
            
        let imageRef = Storage.storage().reference().child("posts").child(User.shared.uid!).child("\(UUID().uuidString)+\(Date())\(dataExtension)")
                imageRef.putData(data0, metadata: nil) { (metaData, error) in
                    imageRef.downloadURL { (url, error) in
                        if error == nil {
                            if let downloadURL = url{
                                completion(downloadURL, imageRef.fullPath)
                            }
                        } else{
                            ProgressHUD.showError("Error")
                            print("error uploading picture")
                            
                        }
                    }
                }
            

        
    }
    
    private func resolutionForLocalVideo(url: URL) -> CGSize? {
        guard let track = AVURLAsset(url: url).tracks(withMediaType: AVMediaType.video).first else { return nil }
       let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
    
    func setUpSendButton(){
        sendButton.setTitle("Done", for: .normal)
        sendButton.setTitleColor(.systemPink, for: .normal)
        sendButton.setTitleColor(UIColor.placeholderText, for: .disabled)
        sendButton.addTarget(self, action:#selector(sendPressed), for:.touchUpInside)
        let sendBarButton = UIBarButtonItem.init(customView: sendButton)
        navigationItem.rightBarButtonItems = [sendBarButton]
    }
    
    func saveToDatabase(photoURL : URL, videoURL : URL?, isVideo : Bool, storageRef : String, videoStorageRef : String){
        let ref = db.collection("users").document(User.shared.uid ?? "").collection("posts").document()
        if textView.text == "Write a caption..."{
            textView.text = ""
        }
        if !isGIF{
        let widthInPixels = self.image.size.width * self.image.scale
        let heightInPixels = self.image.size.height * self.image.scale
        photoSize = CGSize(width: widthInPixels, height: heightInPixels)
        if isVideo{
            photoSize = self.resolutionForLocalVideo(url: self.video!) ?? photoSize
        }
        }
        
        let post = Post(photoURL: photoURL.absoluteString,
                        caption: self.textView.text,
                        publishDate: Date(),
                        creatorID: User.shared.uid ?? "",
                        isVideo: isVideo, videoURL: videoURL?.absoluteString,
                        photoSize: self.photoSize,
                        postID: ref.documentID,
                        isGIF: self.isGIF,
                        challenge: self.challenge,
                        challengeDay: self.challengeDay,
                        tags : self.tags,
                        storageRef : storageRef,
                        videoStorageRef: videoStorageRef )
        ref.setData(post.representation)
        ProgressHUD.showSuccess("Post Successful")
    }
    

}

extension SendToUserViewController : UITextViewDelegate{
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.secondaryLabel {
            textView.text = nil
            textView.textColor = UIColor.label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Write a caption..."
            textView.textColor = UIColor.secondaryLabel
        }
    }
    
    
}

extension  SendToUserViewController : UICollectionViewDelegate, UICollectionViewDataSource, CollectionViewWaterfallLayoutDelegate{
    
    func setUpCollectionView(){
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let layout = CollectionViewWaterfallLayout()
        layout.minimumColumnSpacing = 4
        layout.minimumInteritemSpacing = 4
        collectionView.collectionViewLayout = layout
    }
    
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: self.view.frame.height, height: self.view.frame.width)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return CategoryItem.getCategoryArray().count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "categoryCell", for: indexPath)
        
        let item = CategoryItem.getCategoryArray()[indexPath.row]
        
        let backgroundImage = cell.viewWithTag(1) as! AnimatedImageView
        let colorView = cell.viewWithTag(2)
        let titleLabel = cell.viewWithTag(3) as! UILabel
        let selectedView = cell.viewWithTag(4) as! UIImageView
        
        selectedView.isHidden = !tags.contains(item.id)
        
        backgroundImage.kf.setImage(with: item.url)
        colorView?.backgroundColor = item.color
        titleLabel.text = item.displayName
        
        
        cell.contentView.layer.masksToBounds = true
        cell.contentView.layer.cornerRadius = 10
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let item = CategoryItem.getCategoryArray()[indexPath.row]
        
        if self.tags.contains(item.id){
            tags.removeAll { (tag) -> Bool in
                return tag == item.id
            }
        }else{
        if tags.count < 1{
        self.tags.append(item.id)
        }else if tags.count <= 0{
        }else{
            ProgressHUD.showError("You can only select one tag")
        }
        }
        
        collectionView.reloadItems(at: [indexPath])
    }
    
    
    
}
