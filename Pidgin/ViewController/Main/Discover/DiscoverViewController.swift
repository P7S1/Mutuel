//
//  DiscoverViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 10/8/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import NotificationBannerSwift
import Lightbox
class DiscoverViewController: HomeViewController, ExploreViewControllerDelegate {
    
    var segmentedController: UISegmentedControl!
    
    var exploreVC : ExploreViewController!
    
    var followingVC : FollowingViewController!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isHeroEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(presentNotification), name: NSNotification.Name(rawValue: "presentNotification"), object: nil)
        setupUI()
        
        configureNavItem(name: "Discover")
        let items = ["Discover", "Following"]
        segmentedController = UISegmentedControl(items: items)
        segmentedController.tintColor = .systemPink
        navigationItem.titleView = segmentedController
        segmentedController.addTarget(self, action: #selector(indexChanged(_:)), for: .valueChanged)
        segmentedController.selectedSegmentIndex = 0
        
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
        exploreVC = storyboard.instantiateViewController(withIdentifier: "ExploreViewController") as? ExploreViewController
        exploreVC.exploreDelegate = self
        followingVC  = storyboard.instantiateViewController(withIdentifier: "FollowingViewController") as? FollowingViewController
        followingVC.followingDelegate = self
        addConstraints(view: exploreVC.view)
        addConstraints(view: followingVC.view)
        indexChanged(segmentedController)
        
        //Camera
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                //access granted
            } else {

            }
        }
        //Microphone
        AVCaptureDevice.requestAccess(for: AVMediaType.audio) { (response) in
            if response{
                
            } else{
                
            }
        }
        //Photos
        let photos = PHPhotoLibrary.authorizationStatus()
        if photos == .notDetermined {
            PHPhotoLibrary.requestAuthorization({status in
                if status == .authorized{
                
                } else {}
            })
        }

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Auth.auth().currentUser != nil {
            print("user is signed in")
        } else {
            print("user is not signed in")
            returnToLoginScreen()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isHeroEnabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //navigationController?.isHeroEnabled = false
    }
    
    @objc func indexChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex{
            case 0:
                navigationItem.title = "Discover"
                print("Discover")
                followingVC.removeFromParent()
                followingVC.view.removeFromSuperview()
                followingVC.didMove(toParent: nil)
                self.addChild(exploreVC)
                self.view.addSubview(exploreVC.view)
                exploreVC.didMove(toParent: self)
            case 1:
                print("Following")
                navigationItem.title = "Following"
                exploreVC.removeFromParent()
                exploreVC.view.removeFromSuperview()
                exploreVC.didMove(toParent: nil)
                self.addChild(followingVC)
                self.view.addSubview(followingVC.view)
                followingVC.didMove(toParent: self)
            default:
                break
            }
    }
    
     func addConstraints(view : UIView){
       view.frame = self.view.bounds
     view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    func collectionViewScrolled(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
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

extension UIViewController{
    func returnToLoginScreen(){
        let alert = UIAlertController(title: "Logged Out", message: "You have been logged out, please log back in.", preferredStyle: .alert)
        User.shared.invalidateToken { (completion) in
            User.shared.invalidateUser()
            do{
                try Auth.auth().signOut()
            }catch{
                print("Error signing out: \(error)")
            }
            
        }
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { (action) in
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "WelcomeViewController") as! WelcomeViewController
            vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
}

extension UIViewController{
    
    func getHeaderView(with title : String, tableView : UITableView) -> UIView{
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 50))
         
        
             headerView.backgroundColor = .clear
         

         let label = UILabel()
         label.frame = CGRect.init(x: 5, y: 8, width: headerView.frame.width-10, height: headerView.frame.height-10)
        label.text = title
        label.font = UIFont.systemFont(ofSize: 23 , weight: .bold)
         if #available(iOS 13.0, *) {
            label.textColor = .label
         } else {
            label.textColor = .label
             // Fallback on earlier versions
         } // my custom colour

         headerView.addSubview(label)

         return headerView
    }
    
    func setDismissButton(){
        var settings = UIButton.init(type: .custom)
        if #available(iOS 13.0, *) {
            settings = UIButton.init(type: .close)
        } else {
            settings.setTitle("Dismiss", for: .normal)
            settings.setTitleColor(.systemPink, for: .normal)
            // Fallback on earlier versions
        }
        settings.tintColor = .systemPink
        settings.addTarget(self, action:#selector(handleDismissButton), for:.touchUpInside)
        settings.widthAnchor.constraint(equalToConstant: 25).isActive = true
        settings.heightAnchor.constraint(equalToConstant: 25).isActive = true
        let settingsButton = UIBarButtonItem.init(customView: settings)
        navigationItem.leftBarButtonItems = [settingsButton]
    }
    
    @objc func handleDismissButton(){
        print("settings bar button pressed")
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func presentNotification(_ notification: NSNotification){
        print("notificaiton received")

        if let message = notification.userInfo?["message"] as? String,
            let title = notification.userInfo?["title"] as? String,
            let photoURL = notification.userInfo?["photoURL"] as? String{
            print("notificaiton data: \(title) and \(message)")
            
            let leftView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            leftView.kf.setImage(with: URL(string: photoURL), placeholder: FollowersHelper().getUserProfilePicture())
            leftView.contentMode = .scaleAspectFill
            leftView.clipsToBounds = true
            leftView.layer.cornerRadius = leftView.frame.height/2
            
            let banner = NotificationBanner(title: title, subtitle: message, leftView: leftView, rightView: nil, style: .info, colors: CustomBannerColors())


            banner.duration = 1.5
            if self.viewIfLoaded?.window != nil {
                // viewController is visible
                banner.show()
            }
 
        }else{
            print("notificaiton failed")
        }

        
        
    }
    func presentLightBoxController(images : [LightboxImage], goToIndex : Int?){
      LightboxConfig.CloseButton.text = "Done"
      
      let attributedStringShadow = NSShadow()
      attributedStringShadow.shadowBlurRadius = 5.0
      attributedStringShadow.shadowColor = UIColor.darkGray
      
      let attributes = [NSAttributedString.Key.shadow: attributedStringShadow,
      NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17, weight: .bold)]
      LightboxConfig.CloseButton.textAttributes = attributes
        LightboxConfig.loadImage = {
          imageView, URL, completion in
            imageView.kf.setImage(with: URL)
            completion?(imageView.image)
            imageView.heroID = URL.absoluteString
          // Custom image loading
        }
      // Create an instance of LightboxController.
      let controller = LightboxController(images: images)
      controller.view.tintColor = UIColor.white
      // Use dynamic background.
      controller.dynamicBackground = true
      controller.modalPresentationStyle = .fullScreen
      // Present your controller.
        controller.isHeroEnabled = true
        controller.hero.modalAnimationType = .selectBy(presenting:.zoom, dismissing:.zoomOut)
      controller.tabBarController?.tabBar.isHidden = true
        
      present(controller, animated: true, completion: nil)
        if let index = goToIndex{
            controller.goTo(index)
        }
    }
}

class CustomBannerColors: BannerColorsProtocol {

    internal func color(for style: BannerStyle) -> UIColor {
        switch style {
            case .info:        // Your custom .info color
               return .systemBlue
            default:
            return .systemBlue
        }
    }

}
extension Character {
    /// A simple emoji is one scalar and presented to the user as an Emoji
    var isSimpleEmoji: Bool {
        guard let firstProperties = unicodeScalars.first?.properties else {
            return false
        }
        return unicodeScalars.count == 1 &&
            (firstProperties.isEmojiPresentation ||
                firstProperties.generalCategory == .otherSymbol)
    }

    /// Checks if the scalars will be merged into an emoji
    var isCombinedIntoEmoji: Bool {
        return (unicodeScalars.count > 1 &&
               unicodeScalars.contains { $0.properties.isJoinControl || $0.properties.isVariationSelector })
            || unicodeScalars.allSatisfy({ $0.properties.isEmojiPresentation })
    }

    var isEmoji: Bool {
        return isSimpleEmoji || isCombinedIntoEmoji
    }
}

extension String {
    var isSingleEmoji: Bool {
        return count == 1 && containsEmoji
    }

    var containsEmoji: Bool {
        return contains { $0.isEmoji }
    }

    var containsOnlyEmoji: Bool {
        return !isEmpty && !contains { !$0.isEmoji }
    }

    var emojiString: String {
        return emojis.map { String($0) }.reduce("", +)
    }

    var emojis: [Character] {
        return filter { $0.isEmoji }
    }

    var emojiScalars: [UnicodeScalar] {
        return filter{ $0.isEmoji }.flatMap { $0.unicodeScalars }
    }
}

    class BackGradientView: UIView {
        override open class var layerClass: AnyClass {
           return CAGradientLayer.classForCoder()
        }

        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            let gradientLayer = layer as! CAGradientLayer
            gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        }
    }

