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
class DiscoverViewController: HomeViewController, ExploreViewControllerDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var containerView: UIView!
    
    var exploreVC : ExploreViewController!
    
    var followingVC : FollowingViewController!
    
    
    private enum Constants {
        static let segmentedControlHeight: CGFloat = 48
        static let underlineViewColor: UIColor = .systemPink
        static let underlineViewHeight: CGFloat = 4
    }
    
    private lazy var segmentedControlContainerView: UIView = {
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height:48 ))
        containerView.backgroundColor = .systemBackground
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.isUserInteractionEnabled = true
        return containerView
    }()
    
    private lazy var segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(frame: CGRect(x: 00, y: 0, width: 48, height: self.view.bounds.height))
        segmentedControl.isUserInteractionEnabled = true
        // Remove background and divider color
        segmentedControl.backgroundColor = .clear
        segmentedControl.tintColor = .clear
        segmentedControl.selectedSegmentTintColor  = .clear
        fixBackgroundSegmentControl(segmentedControl)
        // Append segments
        segmentedControl.insertSegment(withTitle: "Discover", at: 0, animated: true)
        segmentedControl.insertSegment(withTitle: "Following", at: 1, animated: true)

        // Select first segment by default
        segmentedControl.selectedSegmentIndex = 0
            
        // Change text color and the font of the NOT selected (normal) segment
        segmentedControl.setTitleTextAttributes([
            NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .medium)], for: .normal)

        // Change text color and the font of the selected segment
        segmentedControl.setTitleTextAttributes([
            NSAttributedString.Key.foregroundColor: UIColor.systemPink,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .bold)], for: .selected)

        // Set up event handler to get notified when the selected segment changes
        segmentedControl.addTarget(self, action: #selector(indexChanged(_:)), for: .valueChanged)
        // Return false because we will set the constraints with Auto Layout
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        return segmentedControl
    }()
    
    // The underline view below the segmented control
    private lazy var bottomUnderlineView: UIView = {
        let underlineView = UIView()
        underlineView.isUserInteractionEnabled = true
        underlineView.backgroundColor = Constants.underlineViewColor
        underlineView.translatesAutoresizingMaskIntoConstraints = false
        return underlineView
    }()

    private lazy var leadingDistanceConstraint: NSLayoutConstraint = {
        return bottomUnderlineView.leftAnchor.constraint(equalTo: segmentedControl.leftAnchor)
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isHeroEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(presentNotification), name: NSNotification.Name(rawValue: "presentNotification"), object: nil)
        setupUI()
        self.configureNavItem(name: "Discover")
        segmentedControlContainerView.addSubview(segmentedControl)
        segmentedControlContainerView.addSubview(bottomUnderlineView)
        addSegmentedControlConstraints()
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
        exploreVC = storyboard.instantiateViewController(withIdentifier: "ExploreViewController") as? ExploreViewController
        exploreVC.adjustInsets = true
        exploreVC.exploreDelegate = self
        followingVC  = storyboard.instantiateViewController(withIdentifier: "FollowingViewController") as? FollowingViewController
        followingVC.followingDelegate = self
        followingVC.adjustInsets = true
        indexChanged(segmentedControl)
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
        navigationController?.isHeroEnabled = false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    @objc func indexChanged(_ sender: UISegmentedControl) {
        changeSegmentedControlLinePosition()
        switch sender.selectedSegmentIndex{
            case 0:
                navigationItem.title = "Discover"
                print("Discover")
                followingVC.removeFromParent()
                followingVC.view.removeFromSuperview()
                followingVC.didMove(toParent: nil)
                self.addChild(exploreVC)
                self.containerView.addSubview(exploreVC.view)
                addConstraints(view: exploreVC.view)
                exploreVC.didMove(toParent: self)
            case 1:
                print("Following")
                navigationItem.title = "Following"
                exploreVC.removeFromParent()
                exploreVC.view.removeFromSuperview()
                exploreVC.didMove(toParent: nil)
                self.addChild(followingVC)
                self.containerView.addSubview(followingVC.view)
                addConstraints(view: followingVC.view)
                followingVC.didMove(toParent: self)
            default:
                break
            }
    }
    
    private func changeSegmentedControlLinePosition() {
        let segmentIndex = CGFloat(segmentedControl.selectedSegmentIndex)
        let segmentWidth = segmentedControl.frame.width / CGFloat(segmentedControl.numberOfSegments)
        let leadingDistance = segmentWidth * segmentIndex
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            self?.leadingDistanceConstraint.constant = leadingDistance
            self?.view.layoutIfNeeded()
        })
    }
    
     func addConstraints(view : UIView){
       view.frame = containerView.bounds
     view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    func collectionViewScrolled(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
    }
    func addSegmentedControlConstraints(){
           self.view.addSubview(segmentedControlContainerView)
       let safeLayoutGuide = self.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            segmentedControlContainerView.topAnchor.constraint(equalTo: safeLayoutGuide.topAnchor),
            segmentedControlContainerView.leadingAnchor.constraint(equalTo: safeLayoutGuide.leadingAnchor),
            segmentedControlContainerView.widthAnchor.constraint(equalTo: safeLayoutGuide.widthAnchor),
            segmentedControlContainerView.heightAnchor.constraint(equalToConstant: Constants.segmentedControlHeight)
            ])
        
        // Constrain the segmented control to the container view
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: segmentedControlContainerView.topAnchor),
            segmentedControl.leadingAnchor.constraint(equalTo: segmentedControlContainerView.leadingAnchor),
            segmentedControl.centerXAnchor.constraint(equalTo: segmentedControlContainerView.centerXAnchor),
            segmentedControl.centerYAnchor.constraint(equalTo: segmentedControlContainerView.centerYAnchor)
            ])

        // Constrain the underline view relative to the segmented control
        NSLayoutConstraint.activate([
            bottomUnderlineView.bottomAnchor.constraint(equalTo: segmentedControl.bottomAnchor),
            bottomUnderlineView.heightAnchor.constraint(equalToConstant: Constants.underlineViewHeight),
            leadingDistanceConstraint,
            bottomUnderlineView.widthAnchor.constraint(equalTo: segmentedControl.widthAnchor, multiplier: 1 / CGFloat(segmentedControl.numberOfSegments))
            ])
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
    func fixBackgroundSegmentControl( _ segmentControl: UISegmentedControl){
        if #available(iOS 13.0, *) {
            //just to be sure it is full loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                for i in 0...(segmentControl.numberOfSegments-1)  {
                    let backgroundSegmentView = segmentControl.subviews[i]
                    //it is not enogh changing the background color. It has some kind of shadow layer
                    backgroundSegmentView.isHidden = true
                }
            }
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
               return .systemPink
            default:
            return .systemPink
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

extension String {
    var isAlphanumeric: Bool {
        return !isEmpty && range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
    }
}
