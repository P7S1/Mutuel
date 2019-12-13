//
//  HomeViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 12/4/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
class HomeViewController : UIViewController, UIScrollViewDelegate, UISearchBarDelegate{
    
    var blurEffectView = UIVisualEffectView()
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.2
    }
    
    
    let imageView = UIButton.init(type: .custom)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        extendedLayoutIncludesOpaqueBars = true
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showImage(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        showImage(false)
    }
    
    private struct Const {
        /// Image height/width for Large NavBar state
        static let ImageSizeForLargeState: CGFloat = 40
        /// Margin from right anchor of safe area to right anchor of Image
        static let ImageRightMargin: CGFloat = 16
        /// Margin from bottom anchor of NavBar to bottom anchor of Image for Large NavBar state
        static let ImageBottomMarginForLargeState: CGFloat = 12
        /// Margin from bottom anchor of NavBar to bottom anchor of Image for Small NavBar state
        static let ImageBottomMarginForSmallState: CGFloat = 6
        /// Image height/width for Small NavBar state
        static let ImageSizeForSmallState: CGFloat = 32
        /// Height of NavBar for Small state. Usually it's just 44
        static let NavBarHeightSmallState: CGFloat = 44
        /// Height of NavBar for Large state. Usually it's just 96.5 but if you have a custom font for the title, please make sure to edit this value since it changes the height for Large state of NavBar
        static let NavBarHeightLargeState: CGFloat = 126.5
    }
    
     func setupUI() {
        navigationController?.navigationBar.prefersLargeTitles = true
        
        if let url = User.shared.profileURL{
            DispatchQueue.main.async {
                self.imageView.kf.setImage(with: URL(string: url), for: .normal, placeholder: FollowersHelper().getUserProfilePicture())
            }
        }
        imageView.addTarget(self, action:#selector(profileBarButtonPressed), for:.touchUpInside)
        guard let navigationBar = self.navigationController?.navigationBar else { return }
        imageView.imageView?.contentMode = .scaleAspectFill
        navigationBar.addSubview(imageView)
        imageView.layer.cornerRadius = Const.ImageSizeForLargeState / 2
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
        imageView.rightAnchor.constraint(equalTo: navigationBar.rightAnchor, constant: -Const.ImageRightMargin),
        imageView.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor, constant: -Const.ImageBottomMarginForLargeState),
        imageView.heightAnchor.constraint(equalToConstant: Const.ImageSizeForLargeState),
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor)
        ])
    }
    
    private func moveAndResizeImage(for height: CGFloat) {
        let coeff: CGFloat = {
            let delta = height - Const.NavBarHeightSmallState
            let heightDifferenceBetweenStates = (Const.NavBarHeightLargeState - Const.NavBarHeightSmallState)
            return delta / heightDifferenceBetweenStates
        }()

        let factor = Const.ImageSizeForSmallState / Const.ImageSizeForLargeState

        let scale: CGFloat = {
            let sizeAddendumFactor = coeff * (1.0 - factor)
            return min(1.0, sizeAddendumFactor + factor)
        }()

        // Value of difference between icons for large and small states
        let sizeDiff = Const.ImageSizeForLargeState * (1.0 - factor) // 8.0

        let yTranslation: CGFloat = {
            /// This value = 14. It equals to difference of 12 and 6 (bottom margin for large and small states). Also it adds 8.0 (size difference when the image gets smaller size)
            let maxYTranslation = Const.ImageBottomMarginForLargeState - Const.ImageBottomMarginForSmallState + sizeDiff
            return max(0, min(maxYTranslation, (maxYTranslation - coeff * (Const.ImageBottomMarginForSmallState + sizeDiff))))
        }()

        let xTranslation = max(0, sizeDiff - coeff * sizeDiff)

        imageView.transform = CGAffineTransform.identity
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: xTranslation, y: yTranslation)
    }
    
     func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let height = navigationController?.navigationBar.frame.height else { return }
        moveAndResizeImage(for: height)
    }
    
     func showImage(_ show: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.imageView.alpha = show ? 1.0 : 0.0
        }
    }
    
    func configureNavItem(name : String){
        

        self.navigationItem.title = name
        navigationController?.navigationBar.prefersLargeTitles = true

        let resultsTableController = storyboard?.instantiateViewController(withIdentifier: "ResultsTableViewController") as! ResultsTableViewController
        let search = UISearchController(searchResultsController: resultsTableController)
        search.searchBar.delegate = self
        search.searchResultsUpdater = resultsTableController
        search.searchBar.autocapitalizationType = .none
        search.searchBar.placeholder = "Search users"
        search.searchBar.tintColor = .systemPink
        search.searchBar.addDoneButtonOnKeyboard()
        
        navigationItem.searchController = search
        
        navigationItem.searchController?.view.bounds = UIScreen.main.bounds
        
       /* let profile = UIButton.init(type: .custom)
        //profile.setImage(UIImage.init(named: "icons8-male-user-96"), for: UIControl.State.normal)
        if let url = User.shared.profileURL{
            DispatchQueue.main.async {
                profile.kf.setImage(with: URL(string: url), for: .normal)
                profile.layer.cornerRadius = profile.bounds.height / 2
            }
        }else{
            profile.setImage(UIImage(named:"icons8-male-user-96"), for: .normal)
        }
        //profile.addTarget(self, action:#selector(profileBarButtonPressed), for:.touchUpInside)
        profile.widthAnchor.constraint(equalToConstant: 28).isActive = true
        profile.heightAnchor.constraint(equalToConstant: 28).isActive = true
        profile.roundCorners()
        profile.imageView?.contentMode = .scaleAspectFill
        let profileButton = UIBarButtonItem.init(customView: profile) */
        if name == "Chats"{
        print("name equals chat")
        // let chat = UIButton.init(type: .custom)
        // chat.setImage(UIImage(systemName: "square.and.pencil"), for: UIControl.State.normal)
         //chat.addTarget(self, action:#selector(chatButtonPressed), for:.touchUpInside)
            let chatButton = UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(chatButtonPressed))
            
        navigationItem.leftBarButtonItems = [chatButton]
        }
        //navigationItem.rightBarButtonItems = [profileButton]
    }
    
    @objc func chatButtonPressed(){
        print("chat bar button item pressed")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "FollowersTableViewController") as! FollowersTableViewController
        
        vc.type = "newMessage"
        
        navigationController?.pushViewController(vc, animated: true)
    }
    @objc func profileBarButtonPressed(){
        print("profile bar button item pressed")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        
        vc.user = User.shared
        vc.isCurrentUser = true
               
        navigationController?.pushViewController(vc, animated: true)
    }
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        showImage(false)
        self.view.addSubview(blurEffectView)
       UIView.animate(withDuration: 0.2) {
        self.blurEffectView.effect = UIBlurEffect(style: UIBlurEffect.Style.regular)
        self.tabBarController?.tabBar.isHidden = true
       }
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        showImage(true)
        UIView.animate(withDuration: 0.2) {
            self.blurEffectView.effect = nil
            self.tabBarController?.tabBar.isHidden = false
            self.blurEffectView.removeFromSuperview()
        }
    }

}
