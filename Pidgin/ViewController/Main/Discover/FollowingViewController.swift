//
//  FollowingViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 12/27/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import DeepDiff
import FirebaseFirestore
import AVKit
import SkeletonView
import DZNEmptyDataSet
import GoogleMobileAds
class FollowingViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var followingDelegate : ExploreViewControllerDelegate?
    
    var posts = [AnyHashable]()
    
    var shouldQuery = true
    
    let cache = NSCache<NSString, User>()
    
   var shouldContinuePlaying = false
    
    var lastDocument : DocumentSnapshot?
    
    var query : Query?
    
    var originalQuery : Query?
    
    var loadedAllPosts = false
    
    var user : Account?
    
    var navTitle = "Discover"
    
    let refreshControl = UIRefreshControl()
    
    var startingPostsCount = 1
    
    var adLoader : GADAdLoader!
    
    var pendingAds : [GADUnifiedNativeAd] = [GADUnifiedNativeAd]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        self.startingPostsCount = posts.count
        self.collectionView.activityIndicator(show: true)
        
       // collectionView.contentInsetAdjustmentBehavior = .never
   
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.emptyDataSetDelegate = self
        collectionView.emptyDataSetSource = self
        setUpAds()
        self.adLoader.load(GADRequest())
        if shouldQuery{
            
            guard let uid = User.shared.uid else{
                fatalError("NO USER ID FOUND")
            }
        originalQuery = db.collection("users").document(uid).collection("feed").order(by: "publishDate", descending: true)
            query = originalQuery?.limit(to: 7)
        }else{
            navigationItem.largeTitleDisplayMode = .never
            navigationItem.title = navTitle
        }
   
        getMorePosts(removeAll: false)
        
        refreshControl.tintColor = .secondaryLabel
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView.addSubview(refreshControl)
        collectionView.alwaysBounceVertical = false
        collectionView.decelerationRate = .normal
        
        self.view.isSkeletonable = true
        
        // Do any additional setup after loading the view.
    }
    
    @objc func refresh(){
        lastDocument = nil
        loadedAllPosts = false
        query = originalQuery?.limit(to: 7)
        getMorePosts(removeAll: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.shouldContinuePlaying = false
        if let visibleIndexPath = self.getVisibleCellsIndexPath(),
            let cell = collectionView.cellForItem(at: visibleIndexPath) as? FollowingCollectionViewCell, let post = posts[visibleIndexPath.row] as? Post{
            
            if post.isVideo{
                cell.playerContainerView.initialize(post: post, shouldPlay: true)
            }
        }
       // self.scrollViewDidEndDecelerating(collectionView)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        if !shouldContinuePlaying{
            self.stopAllVideoCells()
        }
        
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        followingDelegate?.collectionViewScrolled(collectionView)
    }
    

    
    func stopAllVideoCells(){
        print("stopping all video cells")
               for cell in collectionView.visibleCells{
                   if let newCell = cell as? FollowingCollectionViewCell, let player = newCell.playerContainerView  {
                       player.pause()
                   }
               }
        VideoManager().destroyVideos()
           }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
    func getMorePosts(removeAll : Bool){
        
        DispatchQueue.global(qos: .background).async {
            if let lastDoc = self.lastDocument{
                self.query = self.query?.start(afterDocument: lastDoc)
                    }
            self.query?.getDocuments { (snapshot, error) in
                    if error == nil{
                        let old = self.posts
                        if removeAll{
                            self.posts.removeAll()
                        }
                        var newItems = self.posts
                        
                        for document in snapshot!.documents{
                            let post = Post(document: document)
                            self.lastDocument = document
                            if !self.posts.contains(post){
                                newItems.append(post)
                            }

                        }
                        
                        if snapshot!.count-self.startingPostsCount < 7{
                            self.loadedAllPosts = true
                        }else if !self.pendingAds.isEmpty{
                            newItems.insert(self.pendingAds[0], at: newItems.count-Int.random(in: 3...4))
                            self.pendingAds.remove(at: 0)
                        }
                        DispatchQueue.main.async {
                        
                            self.collectionView.activityIndicator(show: false)
                            if self.refreshControl.isRefreshing{
                            self.refreshControl.endRefreshing()
                            }
                            let changes = diff(old: old, new: newItems)
                            self.collectionView.reload(changes: changes, section: 0, updateData: {
                                self.posts = newItems
                                self.collectionView.reloadEmptyDataSet()
                                self.adLoader.load(GADRequest())
                            })
                        }
                      
                    }else{
                        print("there was an error : \(error!)")
                    }
                }
        }
                
    }
    
     func repost(oldPost : Post){
        if oldPost.creatorID != User.shared.uid{
        let controller = UIAlertController(title: "Confirm", message: "Are you sure you want to repost this?", preferredStyle: .alert)
            
        controller.popoverPresentationController?.sourceView = self.view
        controller.popoverPresentationController?.sourceRect = self.view.frame
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            controller.dismiss(animated: true, completion: nil)
        }))
        
        controller.addAction(UIAlertAction(title: "Repost", style: .default, handler: { (action) in
            ProgressHUD.show("Reposting...")
            let post = Post(post: oldPost)
            let docRef = db.collection("users").document(User.shared.uid ?? "").collection("posts").document(post.originalPostID)
            docRef.setData(post.representation, merge: true) { (error) in
                if error == nil{
                    ProgressHUD.showSuccess("Reposted Successfully")
                }else{
                    ProgressHUD.showError("Post Error")
                }
            }
        }))
        
        
        self.present(controller, animated: true, completion: nil)
        }else{
            ProgressHUD.showError("You can't repost your own post")
        }
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

extension FollowingViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row + 1 == posts.count && !self.loadedAllPosts{
            collectionView.activityIndicator(show: true)
            getMorePosts(removeAll: false)
        }
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let post = posts[indexPath.row] as? Post{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FollowingCollectionViewCell", for: indexPath) as! FollowingCollectionViewCell
        
        
        
        let gradient = SkeletonGradient(baseColor: UIColor.secondarySystemBackground)
        
        
        if post.hasChallenge{
            cell.challengeView.isHidden = false
            cell.challengeText.text = "\(post.challengeTitle): Day \(post.dayNumber)"
            cell.challengeView.layer.masksToBounds = true
            cell.challengeView.layer.cornerRadius = cell.challengeView.frame.height/2
        }else{
            cell.challengeView.isHidden = true
        }
        
        
        cell.caption.text = post.caption
        
        cell.playButton.isHidden = !(post.isVideo)
        
        cell.containerView.layer.masksToBounds = true
         cell.containerView.layer.cornerRadius = 10.0

        cell.playerContainerView.layer.masksToBounds = true
       cell.playerContainerView.layer.cornerRadius = 10.0
        cell.playerContainerView.initialize(post: post, shouldPlay: false)
        
        let width = collectionView.bounds.width - 16
        
        let ratio = (width) / post.photoSize.width
        var height = post.photoSize.height * ratio
        height = height + 68
        if height < width{
            height = width
        }

        if height >= collectionView.bounds.height - 68{
            height = collectionView.bounds.height - 68
        }
        
    
        
        
        
            cell.yAnchor.constant = -40
        
        cell.height.constant = height
        cell.contentView.setNeedsUpdateConstraints()
        
        cell.gradientView.isHidden = true
        cell.imageView.isSkeletonable = true
        cell.imageView.showAnimatedGradientSkeleton(usingGradient: gradient)
    cell.imageView.layer.cornerRadius = 10.0
      cell.imageView.clipsToBounds = true
        cell.contentView.isSkeletonable = true
        
        DispatchQueue.main.async {
            cell.imageView.kf.setImage(with: URL(string: post.photoURL)) { (result) in
                   cell.imageView.stopSkeletonAnimation()
                cell.imageView.hideSkeleton(reloadDataAfter: false, transition: .crossDissolve(0.2))
                cell.gradientView.isHidden = false
                
            }
        }
        if post.isRepost{
            cell.usernameLabel.text = "reposted by \(post.reposterUsername) \(post.publishDate.getElapsedInterval())"
        }else{
            cell.usernameLabel.text = post.publishDate.getElapsedInterval()
        }
        cell.nameLabel.text = post.creatorUsername 
            cell.profilePictureView.clipsToBounds = true
            cell.profilePictureView.layer.cornerRadius = cell.profilePictureView.frame.height/2
            DispatchQueue.main.async {
                cell.profilePictureView.kf.setImage(with: URL(string: post.creatorPhotoURL), placeholder: FollowersHelper().getUserProfilePicture())
            }
        
        
        cell.challengeTapAction = {
            () in
            if post.hasChallenge{
                let docRef = db.collection("challenges").document(post.challengeID)
                
                docRef.getDocument { (snapshot, error) in
                    if error == nil{
                        let challenge = Challenge(document: snapshot!)
                        let vc = self.storyboard?.instantiateViewController(identifier: "ChallengeDayViewController") as! ChallengeDayViewController
                        vc.challenge = challenge
                        self.navigationController?.pushViewController(vc, animated: true)
                        
                    }
                }
            }
        }
        
            cell.moreTapAction = {
                () in
                let alertController = UIAlertController(title: nil, message: nil , preferredStyle: .actionSheet)
                alertController.popoverPresentationController?.sourceView = cell.contentView
                alertController.popoverPresentationController?.sourceRect = cell.moreButton.frame
                if post.creatorID == User.shared.uid{
                    alertController.addAction(UIAlertAction(title: "Delete Post", style: .destructive, handler: { (action) in
                        let alertC = UIAlertController(title: "Delete Post?", message: "Are you sure you want to delete this?", preferredStyle: .alert)
                        alertC.popoverPresentationController?.sourceView = self.view
                        alertC.popoverPresentationController?.sourceRect = self.view.frame
                        alertC.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
                            FollowersHelper.deletePost(post: post)
                            if let index = self.posts.firstIndex(of: post){
                                self.posts.remove(at: index)
                                self.collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
                            }
                            
                            ProgressHUD.showSuccess("Post deleted")
                        }))
                        alertC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                        self.present(alertC, animated: true, completion: nil)
                    }))
                }else{
                    alertController.addAction(UIAlertAction(title: "Report", style: .destructive, handler: { (action) in
                        let alertC = UIAlertController(title: "Report Post?", message: "Are you sure you want to report this?", preferredStyle: .alert)
                        
                        alertC.addAction(UIAlertAction(title: "Report", style: .destructive, handler: { (action) in
                             ProgressHUD.showSuccess("Post Reported")
                        }))
                        
                        alertC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                        self.present(alertC, animated: true, completion: nil)
                    }))
                }
                
                if User.shared.uid != post.creatorID && User.shared.uid != post.originalCreatorID{
                alertController.addAction(UIAlertAction(title: "Repost", style: .default, handler: { (action) in
                    self.repost(oldPost: post)
                }))
                }
                
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                    alertController.dismiss(animated: true, completion: nil)
                }))
                self.present(alertController, animated: true, completion: nil)
            }
                        cell.btnTapAction = {
                () in
                print("Edit tapped in cell", indexPath)
                // start your edit process here...
                let storyboard = UIStoryboard(name: "Discover", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "ExploreViewController") as! ExploreViewController
                vc.isUserProfile = true
                if post.originalCreatorID == User.shared.uid{
                vc.user = User.shared
                vc.isCurrentUser = true
                self.navigationController?.pushViewController(vc, animated: true)
                }else{
                    let docRef = db.collection("users").document(post.originalCreatorID)
                    docRef.getDocument { (snapshot, error) in
                        if error == nil{
                            let user = Account()
                            user.convertFromDocument(dictionary: snapshot!)
                            vc.user = user
                            vc.isCurrentUser = false
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                }
            }
            cell.setUpGestures()
        
        
        cell.profilePictureView.clipsToBounds = true
        cell.profilePictureView.layer.cornerRadius = cell.profilePictureView.frame.height/2

        return cell
        }else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FollowingAdCollectionViewCell", for: indexPath) as! FollowingAdCollectionViewCell
            let nativeAd = posts[indexPath.row] as! GADUnifiedNativeAd
            let width = collectionView.bounds.width - 16
                
                let ratio = 1/nativeAd.mediaContent.aspectRatio
            var height = (self.view.frame.width-16) * ratio
                height = height + 68
                if height < width{
                    height = width
                }

                if height >= collectionView.bounds.height - 68{
                    height = collectionView.bounds.height - 68
                }
                
                cell.height.constant = height
            
            cell.adLabel.layer.masksToBounds = true
            cell.adLabel.layer.cornerRadius = cell.adLabel.frame.height/2
            
            cell.adView.nativeAd = nativeAd
            cell.adView.mediaView?.mediaContent = nativeAd.mediaContent
            cell.adView.mediaView?.layer.masksToBounds = true
            cell.adView.mediaView?.layer.cornerRadius = 10
            (cell.adView.headlineView as? UILabel)?.text = nativeAd.headline

            (cell.adView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
            (cell.adView.callToActionView as? UIButton)?.roundCorners()
            cell.adView.callToActionView?.isHidden = nativeAd.callToAction == nil

            (cell.adView.iconView as? UIImageView)?.image = nativeAd.icon?.image
            cell.adView.iconView?.isHidden = nativeAd.icon == nil
            cell.adView.iconView?.layer.masksToBounds = true
            cell.adView.iconView?.layer.cornerRadius = (cell.adView.iconView?.frame.height ?? 0)/2

            (cell.adView.advertiserView as? UILabel)?.text = nativeAd.advertiser
            cell.adView.advertiserView?.isHidden = nativeAd.advertiser == nil

            // In order for the SDK to process touch events properly, user interaction
            // should be disabled.
            (cell.adView.callToActionView as? UIButton)?.isUserInteractionEnabled = false
            

            
            
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        followingDelegate?.collectionViewScrolled(scrollView)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let post = posts[indexPath.row] as? Post{
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PostViewController") as! PostViewController
       // vc.postDelegate = self
        vc.post = post
        shouldContinuePlaying = true
        navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let visibleIndexPath = self.getVisibleCellsIndexPath() else { return }
        if let cell = collectionView.cellForItem(at: visibleIndexPath) as? FollowingCollectionViewCell, let post = posts[visibleIndexPath.row] as? Post{
            cell.setUpPlayer(post: post)
   
        }
    }
    
    func getVisibleCellsIndexPath() -> IndexPath?{
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        return collectionView.indexPathForItem(at: visiblePoint)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let newCell = cell as? FollowingCollectionViewCell, let player = newCell.playerContainerView {
            player.pause()
            
        }
    }


}

extension FollowingViewController : DZNEmptyDataSetSource, DZNEmptyDataSetDelegate{
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
         return UIImage.init(systemName: "person.badge.plus", withConfiguration: EmptyStateAttributes.shared.config)?.withTintColor(.label)
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Empty Feed", attributes: EmptyStateAttributes.shared.title)
    }
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Follow some people to populate it", attributes: EmptyStateAttributes.shared.subtitle)
    }
    
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
           self.showShareAppDialog()
           
       }
       
       
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControl.State) -> NSAttributedString! {
           return NSAttributedString(string: "Invite Friends", attributes: EmptyStateAttributes.shared.button)
       }
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        return self.posts.isEmpty && shouldQuery
    }

    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
    func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
    
}

extension FollowingViewController : GADAdLoaderDelegate,GADUnifiedNativeAdLoaderDelegate  {
    
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADUnifiedNativeAd) {
        print("did recieve ad")
        
        self.pendingAds.append(nativeAd)
    }
    
    
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: GADRequestError) {
        print("there was an ad loading error: \(error.localizedDescription)")
    }
    
    func setUpAds(){
        let mediaOptions = GADNativeAdMediaAdLoaderOptions()
        mediaOptions.mediaAspectRatio = .portrait
        adLoader = GADAdLoader(adUnitID: "ca-app-pub-7404153809143887/2990527942",
            rootViewController: self,
            adTypes: [ GADAdLoaderAdType.unifiedNative ],
            options: [mediaOptions])
        adLoader.delegate = self
        adLoader.load(GADRequest())
    }
    
}
