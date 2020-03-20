//
//  ExploreViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 12/27/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import CollectionViewWaterfallLayout
import DeepDiff
import FirebaseFirestore
import SkeletonView
public protocol ExploreViewControllerDelegate {
   func collectionViewScrolled(_ scrollView: UIScrollView)
}
class ExploreViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var posts = [Post]()
    
    var exploreDelegate : ExploreViewControllerDelegate?
    
    var willPresentAView = false
    
    var lastDocument : DocumentSnapshot?
    
    var originalQuery : Query!
    
    var query : Query!
    
    var loadedAllPosts = false
    
    var isUserProfile = false
    
    var user = Account()
    
    var isCurrentUser = false
    
    var isPresented = false
    
    let refreshControl = UIRefreshControl()
    
    var shouldquery = true
    
    var footer : UICollectionReusableView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        
        
        setUpCollectionView()
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        
        if isUserProfile{
            navigationItem.largeTitleDisplayMode = .never
            navigationItem.title = ""
            
            let appearance = navigationController?.navigationBar.standardAppearance.copy()
            appearance?.backgroundColor = .clear
            appearance?.shadowImage = UIImage()
            appearance?.shadowColor = .clear
            navigationItem.standardAppearance = appearance
            
            query = db.collection("users").document(user.uid ?? "").collection("posts").order(by: "publishDate", descending: true).limit(to: 20)
            originalQuery = query
            
            if user.uid == User.shared.uid ?? ""{
            getMorePosts(removeAll: false)
            setUpRefresh()
            }
            
        }else{
            originalQuery = query
            getMorePosts(removeAll: false)
            setUpRefresh()
        }
        
    
        collectionView.alwaysBounceVertical = true
        
        self.view.isSkeletonable  = true
        
        if isPresented{
           self.setDismissButton()
        }
        
        // Do any additional setup after loading the view.
    }
    
    func setUpRefresh(){
        refreshControl.tintColor = .secondaryLabel
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView.addSubview(refreshControl)
    }
    
    @objc func refresh(){
        lastDocument = nil
        loadedAllPosts = false
        query = originalQuery
        getMorePosts(removeAll: true)
    }
    
    func setBackBarButtonCustom()
    {
        //Back buttion
        let btnLeftMenu: UIButton = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)

        let img = UIImage(systemName: "chevron.left", withConfiguration: config)
        btnLeftMenu.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 2)
        btnLeftMenu.setImage(img, for: .normal)
        btnLeftMenu.backgroundColor = .secondarySystemBackground
        btnLeftMenu.addTarget(self, action: #selector(onClcikBack), for: UIControl.Event.touchUpInside)
        btnLeftMenu.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btnLeftMenu.layer.cornerRadius = btnLeftMenu.frame.height/2
        
        let barButton = UIBarButtonItem(customView: btnLeftMenu)
        self.navigationItem.leftBarButtonItem = barButton
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    @objc func onClcikBack()
    {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    func setUpCollectionView(){
         collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: CollectionViewWaterfallElementKindSectionHeader, withReuseIdentifier: "ProfileHeader")
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: CollectionViewWaterfallElementKindSectionFooter, withReuseIdentifier: "BottomActivity")
        
       let layout = CollectionViewWaterfallLayout()
        
        if navigationController != nil{
            setBackBarButtonCustom()
        }
        
        if isUserProfile{
            let statusBarView = UIView(frame: CGRect(x:0, y:0, width:view.frame.size.width, height: UIApplication.shared.statusBarFrame.height))
            statusBarView.backgroundColor=UIColor.systemBackground
            view.addSubview(statusBarView)
         collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 32, right: 0)
        }else{
         collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 32, right: 0)
        }
        
        // Change individual layout attributes for the spacing between cells'
        layout.minimumColumnSpacing = 4
        layout.minimumInteritemSpacing = 4
        if isUserProfile{
        layout.headerHeight = 160
        }else{
         layout.headerHeight = 0
        }
        layout.footerHeight = 100
        
        // Collection view attributes
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.alwaysBounceVertical = true
        
        // Add the waterfall layout to your collection view
        collectionView.collectionViewLayout = layout
    }
    
    
    func getMorePosts(removeAll : Bool){
        
        if let doc = self.lastDocument{
            query = query.start(afterDocument: doc)
        }
        
        DispatchQueue.main.async {
            self.query.getDocuments { (snapshot, error) in
                  if error == nil{
                      if snapshot!.count < 20{
                          self.loadedAllPosts = true
                          self.updateFooter()
                          self.footer?.activityIndicator(show: false)
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
                          self.refreshControl.endRefreshing()
                      }
                    
                          let changes = diff(old: old, new: newItems)
                          self.collectionView.reload(changes: changes, section: 0, updateData: {
                              self.posts = newItems
                          })
                   
                  }else{
                      self.footer?.activityIndicator(show: false)
                      
                      print("there was an error \(error!)")
                  }
              }
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView,
                 willDisplay cell: UICollectionViewCell,
                   forItemAt indexPath: IndexPath) {
        if indexPath.row + 1 == posts.count && !loadedAllPosts{
            getMorePosts(removeAll: false)
        }
        updateFooter()
    }
    
    
    func updateFooter(){
        let indexes = self.collectionView.indexPathsForVisibleItems
            if indexes.count > 0{
        if let view = self.collectionView.supplementaryView(forElementKind: "CollectionViewWaterfallElementKindSectionFooter", at: indexes[0]){
            view.activityIndicator(show: !self.loadedAllPosts)
        }
            }else{
            let indexPath = IndexPath(row: 0, section: 0)
           if let view = self.collectionView.supplementaryView(forElementKind: "CollectionViewWaterfallElementKindSectionFooter", at: indexPath){
                view.activityIndicator(show: !self.loadedAllPosts)
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

extension ExploreViewController: UICollectionViewDataSource, UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExploreCollectionViewCell", for: indexPath) as! ExploreCollectionViewCell
        let post = posts[indexPath.row]
        
        cell.imageView.clipsToBounds = true
        cell.imageView.layer.cornerRadius = 10
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.imageView.isSkeletonable = true
        let gradient = SkeletonGradient(baseColor: UIColor.secondarySystemBackground)
        cell.imageView.showAnimatedGradientSkeleton(usingGradient: gradient)
            cell.imageView.kf.setImage(with: URL(string: post.photoURL), placeholder: UIImage()) { (result) in
                cell.imageView.stopSkeletonAnimation()
                cell.imageView.hideSkeleton(reloadDataAfter: false, transition: .crossDissolve(0.2))
            }
        
         
        
        
        cell.playButton.isHidden = !(post.isVideo)
        cell.playButton.shouldBlink = false
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
         let vc = storyboard.instantiateViewController(withIdentifier: "FollowingViewController") as! FollowingViewController
        vc.shouldQuery = false
         vc.posts = posts
        vc.indexPath = indexPath
        vc.postDelegate = self
        vc.query = self.query
        vc.originalQuery = self.query
        vc.lastDocument = self.lastDocument
        if isUserProfile{
            vc.navTitle = user.name ?? ""
        }else{
            vc.navTitle = "Trending"
        }
        willPresentAView = true
         navigationController?.pushViewController(vc, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        exploreDelegate?.collectionViewScrolled(scrollView)
    }
    /*
    @objc func settingsBarButtonPressed(){
      if isCurrentUser{
            let storyboard = UIStoryboard(name: "Settings", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "SettingsTableViewController") as! SettingsTableViewController
        navigationController?.pushViewController(vc, animated: true)
        }else{
        if let id1 = User.shared.uid, let id2 = user.uid{
        let docRef = db.collection("channels").document(FollowersHelper().getChannelID(id1: id1, id2: id2))
            docRef.getDocument { (snapshot, error) in
                if error == nil{
                let channel = Channel(document: snapshot!)
                let vc = ChatViewController()
                vc.channel = channel
                self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
            
        }
    }
 */

    
    
}

extension ExploreViewController : CollectionViewWaterfallLayoutDelegate{
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        posts[indexPath.row].photoSize
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case CollectionViewWaterfallElementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ProfileHeader", for: indexPath)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
            vc.user = user
            vc.isCurrentUser = self.isCurrentUser
            vc.profileDelegate = self
            self.addChild(vc, in: header)
            return header
        default:
            footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "BottomActivity", for: indexPath)

            footer!.activityIndicator(show: !self.loadedAllPosts)
            
            return footer!
        }
        
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
           if scrollView.panGestureRecognizer.translation(in: scrollView).y < 0{
               changeNabBar(hidden: true, animated: true)
           }
           else{
               changeNabBar(hidden: false, animated: true)
           }
       }
       
       func changeNabBar(hidden:Bool, animated: Bool){
           navigationController?.setNavigationBarHidden(hidden, animated: animated)
       }
    
}

extension ExploreViewController : PostViewDelegate{
    
    func preparePostsFor(indexPath: IndexPath, posts: [Post], lastDocument: DocumentSnapshot?, loadedAllPosts: Bool) {
        self.loadedAllPosts = loadedAllPosts
        self.lastDocument = lastDocument
        self.collectionView.performBatchUpdates({
            let changes = diff(old: self.posts, new: posts)
            self.collectionView.reload(changes: changes, section: 0, updateData: {
                self.posts = posts
            })
        }) { (completion) in
            if completion{
             self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            }
        }
        
    }

    
    
}

extension ExploreViewController : ProfileDelegate{
    func didFinishFetchingRelationship(relationship: Relationship?) {
        if let item = relationship{
            if item.isApproved{
                self.getMorePosts(removeAll : false)
                self.setUpRefresh()
            }else{
                footer?.activityIndicator(show: false)
            }
        }else{
            footer?.activityIndicator(show: false)
        }
    }
}
