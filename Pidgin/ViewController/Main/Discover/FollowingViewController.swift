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
 protocol PostViewDelegate {
    func preparePostsFor(indexPath: IndexPath, posts : [Post], lastDocument : DocumentSnapshot?, loadedAllPosts : Bool)
}
class FollowingViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var followingDelegate : ExploreViewControllerDelegate?
    
    var postDelegate : PostViewDelegate?
    
    var posts = [Post]()
    
    var shouldQuery = true
    
    var indexPath : IndexPath?
    
    let cache = NSCache<NSString, User>()
    
    var activityIndicator : UIActivityIndicatorView!
    
   var shouldContinuePlaying = false
    
    var lastDocument : DocumentSnapshot?
    
    var query : Query!
    
    var originalQuery : Query!
    
    var loadedAllPosts = false
    
    var user : Account?
    
    var navTitle = "Discover"
    
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton

        self.activityIndicator = UIActivityIndicatorView(style: .large)
        self.activityIndicator.frame = CGRect(x: 0, y: 0, width: 46, height: 46)
        
        
        self.activityIndicator.hidesWhenStopped = true
        
        collectionView.addSubview(activityIndicator)
        
        activityIndicator.startAnimating()
        
       // collectionView.contentInsetAdjustmentBehavior = .never
   
        collectionView.delegate = self
        collectionView.dataSource = self
        if shouldQuery && User.shared.following.count > 0{
            guard let uid = User.shared.uid else{
                self.dismiss(animated: true, completion: nil)
                return
            }
        query = db.collection("users").document(uid).collection("feed").limit(to: 10).order(by: "publishDate", descending: true) 
        originalQuery = query
            getMorePosts(removeAll: false)
        }else{
            activityIndicator.stopAnimating()
            navigationItem.largeTitleDisplayMode = .never
            navigationItem.title = navTitle
        }
        
        refreshControl.tintColor = .secondaryLabel
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView.addSubview(refreshControl)
        collectionView.alwaysBounceVertical = true
        
        self.view.isSkeletonable = true
        
        // Do any additional setup after loading the view.
    }
    
    @objc func refresh(){
        lastDocument = nil
        loadedAllPosts = false
        query = originalQuery
        getMorePosts(removeAll: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.indexPath = nil
        self.shouldContinuePlaying = false
        if let visibleIndexPath = self.getVisibleCellsIndexPath(),
            let cell = collectionView.cellForItem(at: visibleIndexPath) as? FollowingCollectionViewCell{
            if posts[visibleIndexPath.row].isVideo{
                cell.playerContainerView.initialize(post: posts[visibleIndexPath.row], shouldPlay: false)
            }
        }
        self.scrollViewDidEndDecelerating(collectionView)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if collectionView.indexPathsForVisibleItems.count > 0{
        postDelegate?.preparePostsFor(indexPath: collectionView.indexPathsForVisibleItems[0], posts: posts, lastDocument: self.lastDocument, loadedAllPosts: self.loadedAllPosts)
        }
        
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
        if let path = indexPath{
            collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.scrollToItem(at: path, at: [.centeredVertically], animated: false)
        }
        
    }
    
    func getMorePosts(removeAll : Bool){
        
                if let lastDoc = lastDocument{
                    query = query.start(afterDocument: lastDoc)
                }
        
            query.getDocuments { (snapshot, error) in
                if error == nil{
                    if snapshot!.count < 10{
                        self.loadedAllPosts = true
                    }
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
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.collectionView.activityIndicator(show: false)
                        self.refreshControl.endRefreshing()
                    }
                
           
                        let changes = diff(old: old, new: newItems)
                        self.collectionView.reload(changes: changes, section: 0, updateData: {
                            self.posts = newItems
                        })
                  
                }else{
                    print("there was an error : \(error!)")
                }
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FollowingCollectionViewCell", for: indexPath) as! FollowingCollectionViewCell
        
        let gradient = SkeletonGradient(baseColor: UIColor.secondarySystemBackground)
        let post = posts[indexPath.row]
        

        cell.caption.text = post.caption
        
        cell.imageView.heroID = post.postID
 
        cell.caption.heroID = "\(post.postID).caption"
        
        cell.playButton.isHidden = !(posts[indexPath.row].isVideo)
        
        cell.playButton.heroID = "\(post.postID).playButton"
        
        cell.playerContainerView.heroID = "\(post.postID).player"
        cell.containerView.layer.masksToBounds = true
        cell.containerView.layer.cornerRadius = 20.0

        cell.playerContainerView.layer.masksToBounds = true
        cell.playerContainerView.layer.cornerRadius = 20.0
        cell.playerContainerView.initialize(post: post, shouldPlay: false)
        
        
        let ratio = (collectionView.bounds.width) / post.photoSize.width
        var height = post.photoSize.height * ratio
        if height < collectionView.bounds.width{
            height = collectionView.bounds.width
        }
        var constant : CGFloat = 00
        if !shouldQuery{
            constant = 48
        }
        if height >= collectionView.bounds.height - 132 - constant{
            height = collectionView.bounds.height - 132 - constant
        }
        
    
        
        
        if shouldQuery{
            cell.yAnchor.constant = -35
        }
        cell.height.constant = height
        cell.contentView.setNeedsUpdateConstraints()
        
        cell.gradientView.isHidden = true
        cell.imageView.showAnimatedGradientSkeleton(usingGradient: gradient)
        cell.imageView.layer.cornerRadius = 20.0
        cell.imageView.clipsToBounds = true
        cell.contentView.isSkeletonable = true
        DispatchQueue.main.async {
            cell.imageView.kf.setImage(with: URL(string: post.photoURL)) { (result) in
                   cell.imageView.stopSkeletonAnimation()
                cell.imageView.hideSkeleton(reloadDataAfter: false, transition: .crossDissolve(0.2))
                UIView.animate(withDuration: 0.2) {
                    cell.imageView.layer.cornerRadius = 20.0
                    cell.gradientView.isHidden = false
                }
            }
        }
        cell.usernameLabel.text = post.publishDate.getElapsedInterval()
        cell.nameLabel.text = post.creatorUsername 
            cell.profilePictureView.clipsToBounds = true
            cell.profilePictureView.layer.cornerRadius = cell.profilePictureView.frame.height/2
            DispatchQueue.main.async {
                cell.profilePictureView.kf.setImage(with: URL(string: post.creatorPhotoURL), placeholder: FollowersHelper().getUserProfilePicture())
            }
            cell.moreTapAction = {
                () in
                let alertController = UIAlertController(title: nil, message: nil , preferredStyle: .actionSheet)
                if post.creatorID == User.shared.uid{
                    alertController.addAction(UIAlertAction(title: "Delete Post", style: .destructive, handler: { (action) in
                        let alertC = UIAlertController(title: "Delete Post?", message: "Are you sure you want to delete this?", preferredStyle: .alert)
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
                if post.creatorID == User.shared.uid{
                vc.user = User.shared
                vc.isCurrentUser = true
                self.navigationController?.pushViewController(vc, animated: true)
                }else{
                    let docRef = db.collection("users").document(post.creatorID)
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
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PostViewController") as! PostViewController
       // vc.postDelegate = self
        vc.post = posts[indexPath.row]
        shouldContinuePlaying = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let visibleIndexPath = self.getVisibleCellsIndexPath() else { return }
        if let cell = collectionView.cellForItem(at: visibleIndexPath) as? FollowingCollectionViewCell{
            cell.setUpPlayer(post: posts[visibleIndexPath.row])
   
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
