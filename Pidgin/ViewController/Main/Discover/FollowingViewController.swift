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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.isHeroEnabled = true
   
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        if shouldQuery{

        let docRef = db.collectionGroup("posts")
        
        docRef.getDocuments { (snapshot, error) in
            if error == nil{
                let old = self.posts
                var newItems = self.posts
                for document in snapshot!.documents{
                    let post = Post(document: document)
                    newItems.append(post)
                    print("append a post")
                }
                newItems.shuffle()
                self.collectionView.performBatchUpdates({
                    let changes = diff(old: old, new: newItems)
                    self.collectionView.reload(changes: changes, section: 0, updateData: {
                        self.posts = newItems
                    })
                }, completion: nil)
            }
        }
        }else{
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        postDelegate?.preparePostsFor(indexPath: collectionView.indexPathsForVisibleItems[0], posts: posts)
        navigationController?.isHeroEnabled = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let path = indexPath{
            self.collectionView.scrollToItem(at: path, at: [.top], animated: true)
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
 
        
        cell.containerView.layer.masksToBounds = true
        cell.containerView.layer.cornerRadius = 20.0
        

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
        
        let ratio = (collectionView.bounds.width) / posts[indexPath.row].photoSize.width
        let height = posts[indexPath.row].photoSize.height * ratio
    
        return CGSize(width: collectionView.bounds.width, height: height)
        
    }
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        followingDelegate?.collectionViewScrolled(scrollView)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PostViewController") as! PostViewController
       // vc.postDelegate = self
        vc.post = posts[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func collectionViewScrolled(_ scrollView: UIScrollView) {
        scrollViewDidScroll(scrollView)
    }
}

