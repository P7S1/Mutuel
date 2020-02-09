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
class SendToUserViewController: UIViewController {
    var video : URL?
    var image = UIImage()
    var size = CGSize()
    var gifURL : String?
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    
    let sendButton = UIButton.init(type: .custom)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.delegate = self
        navigationItem.title = "New Post"
        setDismissButton()
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        if let gifString = self.gifURL, let gifURL = URL(string: gifString){
        let gradient = SkeletonGradient(baseColor: UIColor.secondarySystemBackground)
            imageView.showAnimatedGradientSkeleton(usingGradient: gradient)
            imageView.kf.setImage(with: gifURL) { (result) in
                self.imageView.hideSkeleton()
            }
        }else{
        imageView.image = image
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        sendButton.isEnabled = true
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    

    
    @objc func sendPressed(){
        print("send pressed")
        sendButton.isEnabled = false
        ProgressHUD.show("Posting")
        
        if let gifString = self.gifURL, let gifURL = URL(string: gifString){
            self.saveToDatabase(photoURL: gifURL, videoURL: nil, isVideo: false)
        }else{
            postMedia(isVideo: false) { (photoURL) in
                if self.video != nil{
                    self.postMedia(isVideo: true) { (videoURL) in
                        self.saveToDatabase(photoURL: photoURL, videoURL: videoURL, isVideo: true)
                    }
                }else{
                    self.saveToDatabase(photoURL: photoURL, videoURL: nil, isVideo: false)
                }
            }
        }
        self.view.window!.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    
    func postMedia(isVideo : Bool, completion: @escaping (URL) -> Void){
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
            
        let imageRef = Storage.storage().reference().child("posts").child(User.shared.uid ?? "").child("\(UUID().uuidString)+\(Date())\(dataExtension)")
                imageRef.putData(data0, metadata: nil) { (metaData, error) in
                    imageRef.downloadURL { (url, error) in
                        if error == nil {
                            if let downloadURL = url{
                            completion(downloadURL)
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
    
    func saveToDatabase(photoURL : URL, videoURL : URL?, isVideo : Bool){
        let ref = db.collection("users").document(User.shared.uid ?? "").collection("posts").document()
        if textView.text == "Write a caption..."{
            textView.text = ""
        }
        let widthInPixels = self.image.size.width * self.image.scale
        let heightInPixels = self.image.size.height * self.image.scale
        var imageSize = CGSize(width: widthInPixels, height: heightInPixels)
        if isVideo{
            imageSize = self.resolutionForLocalVideo(url: self.video!) ?? imageSize
        }
        let post = Post(photoURL: photoURL.absoluteString,
                        caption: self.textView.text,
                        publishDate: Date(),
                        creatorID: User.shared.uid ?? "",
                        isVideo: isVideo, videoURL: videoURL?.absoluteString,
                        photoSize: imageSize,
                        postID: ref.documentID)
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
