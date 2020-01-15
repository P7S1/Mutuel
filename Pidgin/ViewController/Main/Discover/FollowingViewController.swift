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
 protocol PostViewDelegate {
    func preparePostsFor(indexPath: IndexPath, posts : [Post])
}
class FollowingViewController: UIViewController, ExploreViewControllerDelegate {
    

    
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var followingDelegate : ExploreViewControllerDelegate?
    
    var postDelegate : PostViewDelegate?
    
    var posts = [Post]()
    
    var shouldQuery = true
    
    var indexPath : IndexPath?
    
    let cache = NSCache<NSString, User>()
    
    var activityIndicator : UIActivityIndicatorView!
    
    var adjustInsets = false
    
   var shouldContinuePlaying = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.isHeroEnabled = true
        self.activityIndicator = UIActivityIndicatorView(style: .medium)
        self.activityIndicator.frame = CGRect(x: 0, y: 0, width: 46, height: 46)
        
        
        
        self.activityIndicator.hidesWhenStopped = true
        
        collectionView.addSubview(activityIndicator)
        
        activityIndicator.startAnimating()
   
        collectionView.delegate = self
        collectionView.dataSource = self
        if adjustInsets{
        collectionView.contentInset = UIEdgeInsets(top: 62, left: 0, bottom: 0, right: 0)
        }else{
         collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        if shouldQuery && User.shared.following.count > 0{
        let docRef = db.collectionGroup("posts").order(by: "publishDate", descending: true).whereField("creatorID", in: User.shared.following)
        
        docRef.getDocuments { (snapshot, error) in
            if error == nil{
                let old = self.posts
                var newItems = self.posts
                for document in snapshot!.documents{
                    let post = Post(document: document)

                    newItems.append(post)
                    
                    print("append a post")
                }
                self.activityIndicator.stopAnimating()
                self.collectionView.performBatchUpdates({
                    let changes = diff(old: old, new: newItems)
                    self.collectionView.reload(changes: changes, section: 0, updateData: {
                        self.posts = newItems
                    })
                }, completion: nil)
            }else{
                print("there was an error : \(error!)")
            }
        }
        }else{
            activityIndicator.stopAnimating()
            navigationItem.largeTitleDisplayMode = .never
            navigationItem.title = "Discover"
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isHeroEnabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.indexPath = nil
        self.scrollViewDidEndDecelerating(collectionView)
        self.shouldContinuePlaying = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        postDelegate?.preparePostsFor(indexPath: collectionView.indexPathsForVisibleItems[0], posts: posts)
        navigationController?.isHeroEnabled = false
        
        if self.isMovingFromParent{
            print("is moving from parenr")
            self.stopAllVideoCells()
        }else{
            if !shouldContinuePlaying{
                self.stopAllVideoCells()
            }
        }
        
        

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
        collectionView.collectionViewLayout.invalidateLayout()
        if let path = indexPath{
            self.collectionView.scrollToItem(at: path, at: [.centeredVertically], animated: true)
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
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FollowingCollectionViewCell", for: indexPath) as! FollowingCollectionViewCell
        
        let post = posts[indexPath.row]
        
        cell.addButtonShadows()
        
        cell.contentView.backgroundColor = .clear
        cell.imageView.kf.setImage(with: URL(string: post.photoURL))
        cell.caption.text = post.caption
        cell.repostsLabel.text = String(post.repostsCount)
        cell.commentsLabel.text = String(post.commentsCount)
        
        cell.imageView.heroID = post.postID
        cell.engagementStackView.heroID = "\(posts[indexPath.row].postID).engagementStackView"
        cell.caption.heroID = "\(post.postID).caption"
        cell.blurView.heroID = "\(post.postID).engagementStackView"
        
        
        cell.playButton.isHidden = !(posts[indexPath.row].isVideo)
        
        
        cell.playButton.heroID = "\(posts[indexPath.row].postID).playButton"
        
        self.view.isHeroEnabled = true
        self.view.heroID = "\(post.postID).view"
        
        
        cell.playerContainerView.heroModifiers = [.useNoSnapshot, .autolayout]
        cell.imageView.heroModifiers = [.useNoSnapshot, .autolayout]
        cell.containerView.layer.masksToBounds = true
        cell.containerView.layer.cornerRadius = 20.0
    
        
        let ratio = (collectionView.bounds.width) / post.photoSize.width
        var height = post.photoSize.height * ratio
        if height < collectionView.bounds.width{
            height = collectionView.bounds.width
        }
        if height > collectionView.bounds.height-56{
            height = collectionView.bounds.height-56
        }
        cell.height.constant = height
        
      //  cell.backgroundColor = UIColor.random


        if let user = cache.object(forKey: post.creatorID as NSString) {
            // use the cached version
            cell.usernameLabel.text = "@\(user.username ?? "")"
            cell.nameLabel.text = user.name ?? ""
            cell.profilePictureView.kf.setImage(with: URL(string: user.profileURL ?? ""))
                        cell.btnTapAction = {
                () in
                print("Edit tapped in cell", indexPath)
                // start your edit process here...
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
                if user == User.shared{
                vc.user = User.shared
                vc.isCurrentUser = true
                }else{
                    vc.user = user
                    vc.isCurrentUser = false
                }
                self.navigationController?.isHeroEnabled = false
                self.navigationController?.pushViewController(vc, animated: true)
            }
            cell.setUpGestures()
        } else {
            cell.usernameLabel.text = "-"
            cell.nameLabel.text = "-"
            // create it from scratch then store in the cache
            let query = db.collection("users").document(post.creatorID)
            query.getDocument { (snapshot, error) in
                if error == nil{
                    let user = User()
                    user.convertFromDocument(dictionary: snapshot!)
                    self.collectionView.performBatchUpdates({
                        if let index = self.posts.firstIndex(of: post){
                            self.posts[index].user = user
                        self.cache.setObject(user, forKey: post.creatorID as NSString)
                            let indep = IndexPath(row: index, section: 0)
                            collectionView.reloadItems(at: [indep])
                        
                    }
                    }, completion: nil)
                }
            }
        }
        
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
        self.shouldContinuePlaying = true
        vc.isHeroEnabled = true
        let navController = UINavigationController(rootViewController: vc)
        navController.isHeroEnabled = true
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
        //navigationController?.pushViewController(viewController: navController, animated: true, completion:nil)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let visibleIndexPath = self.getVisibleCellsIndexPath() else { return }
        if let cell = collectionView.cellForItem(at: visibleIndexPath) as? FollowingCollectionViewCell{
            cell.setUpPlayer(post: posts[visibleIndexPath.row])
   
        }
       /* for cell in collectionView.visibleCells{
            if let newCell = cell as? FollowingCollectionViewCell, let player = newCell.playerContainerView  {
                if player.post?.isVideo ?? false{
                    print("will play video count : \(collectionView.visibleCells.count)")
                    player.play()
                }else{
                    player.pause()
                    player.isHidden = true
                }
            }
        } */
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
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let newCell = cell as? FollowingCollectionViewCell{
            newCell.playerContainerView.initialize(post: posts[indexPath.row], shouldPlay: true)
        }
    }
    
    
    
    
    func collectionViewScrolled(_ scrollView: UIScrollView) {
        
        scrollViewDidScroll(scrollView)
        
    }
}
