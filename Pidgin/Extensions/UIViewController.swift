//
//  UIViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 2/11/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import Foundation
import FirebaseAuth
import Lightbox
import NotificationBannerSwift
import SPPermissions
extension UIViewController{
    func returnToLoginScreen(){
        let alert = UIAlertController(title: "Logged Out", message: "You have been logged out, please log back in.", preferredStyle: .alert)
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = self.view.frame
        User.shared.invalidateToken { (completion) in
            User.shared.invalidateUser()
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { (action) in
                let storyboard = UIStoryboard(name: "Login", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "WelcomeViewController") as! WelcomeViewController
                vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: true, completion: nil)
            }))
            self.present(alert, animated: true) {
                do{
                    try Auth.auth().signOut()
                }catch{
                    print("Error signing out: \(error)")
                }
            }
            
        }
    }
}

extension UIViewController{
    
    func getHeaderView(with title : String, tableView : UITableView) -> UIView{
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 50))
         
        
             headerView.backgroundColor = .clear
         

         let label = UILabel()
         label.frame = CGRect.init(x:16, y: 8, width: headerView.frame.width-10, height: headerView.frame.height-10)
        label.text = title
        label.font = UIFont.systemFont(ofSize: 21 , weight: .bold)
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
        
      present(controller, animated: true, completion: nil)
        if let index = goToIndex{
            controller.goTo(index)
        }
    }
    
        func addChild(_ controller: UIViewController, in containerView: UIView) {
            self.addChild(controller)
            controller.view.frame = containerView.bounds
            containerView.addSubview(controller.view)
        }
    
    
    
}


extension UIViewController : SPPermissionsDelegate, SPPermissionsDataSource{
    func showPerimissionsVC(){
        
        let controller = SPPermissions.dialog([.camera, .photoLibrary, .microphone])

        // Ovveride texts in controller
        controller.titleText = "Make A Post"
        controller.headerText = "Permissions Required"
        controller.footerText = "These permissions are required for you to post photos from your gallery and to take photos and videos "

        // Set `DataSource` or `Delegate` if need.
        // By default using project texts and icons.
        controller.dataSource = self
        controller.delegate = self

        // Always use this method for present
        controller.present(on: self)
        
    }
    
    public func configure(_ cell: SPPermissionTableViewCell, for permission: SPPermission) -> SPPermissionTableViewCell {
        
        if permission == .camera{
            cell.permissionDescriptionLabel.text = "Take photos and videos"
        } else if permission == .microphone{
            cell.permissionDescriptionLabel.text = "Record audio in videos"
        } else if permission == .photoLibrary{
            cell.permissionDescriptionLabel.text = "Import photos and videos from your camera roll"
        }
        cell.iconView.color = .label
        cell.button.allowedBackgroundColor = .systemPink
        cell.button.allowTitleColor = .systemPink
        return cell
    }
    
    public func deniedData(for permission: SPPermission) -> SPPermissionDeniedAlertData? {
        if permission == .photoLibrary ||
         permission == .camera ||
         permission == .microphone{
            let data = SPPermissionDeniedAlertData()
            data.alertOpenSettingsDeniedPermissionTitle = "Permission was denied"
            data.alertOpenSettingsDeniedPermissionDescription = "Please go to Settings and allow the permission."
            data.alertOpenSettingsDeniedPermissionButtonTitle = "Settings"
            data.alertOpenSettingsDeniedPermissionCancelTitle = "Cancel"
            return data
        } else {
            // If returned nil, alert will not show.
            return nil
        }
    }
    
    @objc public func didHide(permissions ids: [Int]) {
        if (SPPermission.camera.isAuthorized &&
            SPPermission.microphone.isAuthorized &&
            SPPermission.photoLibrary.isAuthorized) {
            
            showUploadVC(challenge: nil, day: nil, isChallenge: false)
            
        }
    }
    
    func showUploadVC(challenge : Challenge?, day : ChallengeDay?, isChallenge: Bool){
        let vc = UploadViewController()
        vc.challenge = challenge
        vc.isChallenge = isChallenge
        vc.challengeDay = day
        self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    func launchUploadVCIfPossible(challenge : Challenge?, day : ChallengeDay?, isChallenge: Bool){
        if SPPermission.camera.isAuthorized &&
                       SPPermission.microphone.isAuthorized &&
                       SPPermission.photoLibrary.isAuthorized {
                       
            showUploadVC(challenge: challenge, day: day, isChallenge: isChallenge)
                       
                   }else{
                       showPerimissionsVC()

                   }
    }
    
    func showShareAppDialog(){
        // text to share
        let link = "https://itunes.apple.com/app/id1498709902?action=write-review"
        let text = "Follow me on Mutuel @\(User.shared.username!). Here is the download link: \(link)"

        // set up activity view controller
        let textToShare = [ text ]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }
}
