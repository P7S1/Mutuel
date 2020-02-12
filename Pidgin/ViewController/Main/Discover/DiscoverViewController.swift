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
import CollectionViewWaterfallLayout
class DiscoverViewController: HomeViewController, ExploreViewControllerDelegate, UICollectionViewDelegate, CollectionViewWaterfallLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return exploreVC.posts[indexPath.row].photoSize
    }
    
    
    @IBOutlet weak var containerView: UIView!
    
    var exploreVC : ExploreViewController!
    
    var followingVC : FollowingViewController!
    
    
    private enum Constants {
        static let segmentedControlHeight: CGFloat = 35
        static let underlineViewColor: UIColor = .systemPink
        static let underlineViewHeight: CGFloat = 2
    }
    
    private lazy var segmentedControlContainerView: UIView = {
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height:Constants.segmentedControlHeight ))
        containerView.backgroundColor = .systemBackground
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.isUserInteractionEnabled = true
        return containerView
    }()
    
    private lazy var segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(frame: CGRect(x: 00, y: 0, width: Constants.segmentedControlHeight, height: self.view.bounds.height))
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
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15, weight: .medium)], for: .normal)

        // Change text color and the font of the selected segment
        segmentedControl.setTitleTextAttributes([
            NSAttributedString.Key.foregroundColor: UIColor.systemPink,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15, weight: .bold)], for: .selected)

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
        indexChanged(segmentedControl)
        navigationItem.largeTitleDisplayMode = .never

        
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
                self.addConstraints(view: exploreVC.view)
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
        let safeLayoutGuide = self.view.safeAreaLayoutGuide
       view.frame = containerView.bounds
        view.translatesAutoresizingMaskIntoConstraints = false
        view.topAnchor.constraint(equalTo: safeLayoutGuide.topAnchor).isActive = true
        view.rightAnchor.constraint(equalTo: safeLayoutGuide.rightAnchor).isActive = true
        view.leftAnchor.constraint(equalTo: safeLayoutGuide.leftAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    super.scrollViewDidScroll(scrollView)
        var verticalOffset = scrollView.contentOffset.y + 42
        

        if scrollView.refreshControl?.isRefreshing ?? false {
            verticalOffset += 60 // After is refreshing changes its value the toolbar goes 60 points down
            print(segmentedControlContainerView.frame.origin.y)
        }

        if verticalOffset >= 0 {
            segmentedControlContainerView.transform = .identity
        } else {
            segmentedControlContainerView.transform = CGAffineTransform(translationX: 0, y: -verticalOffset)
        }
    }
    
    func collectionViewScrolled(_ scrollView: UIScrollView) {
        self.scrollViewDidScroll(scrollView)
        
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

