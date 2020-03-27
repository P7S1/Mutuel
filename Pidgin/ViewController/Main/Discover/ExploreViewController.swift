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
import DZNEmptyDataSet
import GoogleMobileAds
public protocol ExploreViewControllerDelegate {
   func collectionViewScrolled(_ scrollView: UIScrollView)
}
class ExploreViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var posts = [AnyHashable]()
    
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
    
    var isChallenge = false
    
    var vc : ProfileViewController?
    
    var adLoader : GADAdLoader!
    
    var pendingAds : [GADUnifiedNativeAd] = [GADUnifiedNativeAd]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.emptyDataSetSource = self
        collectionView.emptyDataSetDelegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
        setUpAds()
        
        
        setUpCollectionView()
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton

        self.adLoader.load(GADRequest())
        if isUserProfile{
            navigationItem.largeTitleDisplayMode = .never
            navigationItem.title = ""
            
            let appearance = navigationController?.navigationBar.standardAppearance.copy()
            appearance?.backgroundColor = .clear
            appearance?.shadowImage = UIImage()
            appearance?.shadowColor = .clear
            navigationItem.standardAppearance = appearance
            
            originalQuery = db.collection("users").document(user.uid ?? "").collection("posts").order(by: "publishDate", descending: true).whereField("isPrivate", isEqualTo: user.isPrivate)
            query = originalQuery.limit(to: 15)
            
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
        
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            // It's an iPhone
            layout.columnCount = 2
        case .pad:
            // It's an iPad (or macOS Catalyst)
            layout.columnCount = 3
        default:
            // Uh, oh! What could it be?
            layout.columnCount = 2
        }
        // Change individual layout attributes for the spacing between cells'
        layout.minimumColumnSpacing = 4
        layout.minimumInteritemSpacing = 4
        if isUserProfile{
        layout.headerHeight = 160
        let statusBarView = UIView(frame: CGRect(x:0, y:0, width:view.frame.size.width, height: UIApplication.shared.statusBarFrame.height))
           statusBarView.backgroundColor=UIColor.systemBackground
           view.addSubview(statusBarView)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 32, right: 0)
        }else if isChallenge{
            layout.headerHeight = 46
            collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 32, right: 0)
        }else{
          layout.headerHeight = 0
          collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 32, right: 0)
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
                    let old = self.posts
                    var newItems = old
                    
                    if removeAll{
                        newItems.removeAll()
                    }
                    
                    for document in snapshot!.documents{
                                  let post = Post(document: document)
                                newItems.append(post)
                                  self.lastDocument = document
                               /* if !old.contains(where: post){
                                  newItems.append(post)
                                  } */
    
                              }
                    
                      if snapshot!.count < 15{
                          self.loadedAllPosts = true
                          self.updateFooter()
                          self.footer?.activityIndicator(show: false)
                      }else if !self.pendingAds.isEmpty{
                        newItems.insert(self.pendingAds[0], at: newItems.count-Int.random(in: 7...11))
                        self.pendingAds.remove(at: 0)
                    }
                    
                  
                      DispatchQueue.main.async {
                          self.refreshControl.endRefreshing()
                      }
                        
                          let changes = diff(old: old, new: newItems)
                    

                        self.collectionView.reload(changes: changes, section: 0, updateData: {
                            self.posts = newItems
                            self.collectionView.reloadEmptyDataSet()
                            self.adLoader.load(GADRequest())
                        })
                    
                          
                   
                  }else{
                      self.footer?.activityIndicator(show: false)
                      
                      print("there was an error \(error!)")
                  }
                self.collectionView.reloadEmptyDataSet()
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
        
        if let post = posts[indexPath.row] as? Post{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExploreCollectionViewCell", for: indexPath) as! ExploreCollectionViewCell
        
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
        }else{
            print("found an ad!")
            let nativeAd = posts[indexPath.row] as! GADUnifiedNativeAd
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExploreAdCollectionViewCell", for: indexPath) as! ExploreAdCollectionViewCell
            
            cell.setUpView()
            
            cell.adView.nativeAd = nativeAd
            cell.adView.mediaView?.mediaContent = nativeAd.mediaContent
            
            (cell.adView.headlineView as? UILabel)?.text = nativeAd.headline
            
            (cell.adView.advertiserView as? UILabel)?.text = nativeAd.advertiser
            cell.adView.advertiserView?.isHidden = nativeAd.advertiser == nil
            
            (cell.adView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
            (cell.adView.callToActionView as? UIButton)?.isUserInteractionEnabled = false
            cell.adView.callToActionView?.isHidden = nativeAd.callToAction == nil
            
            cell.adView.callToActionView?.isUserInteractionEnabled = false
            (cell.adView.callToActionView as? UIButton)?.roundCorners()
            
            
            
            return cell
            
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let post = posts[indexPath.row] as? Post{
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
         let vc = storyboard.instantiateViewController(withIdentifier: "FollowingViewController") as! FollowingViewController
        vc.shouldQuery = false
        //vc.postDelegate = self
        var query = self.originalQuery

        if self.isChallenge && !post.tags.isEmpty && post.tags.count <= 10 {
            query = originalQuery.whereField("tags", arrayContainsAny: post.tags)
        }
        query = query?.start(atDocument: post.document!).limit(to: 10)
        vc.query = query
        vc.originalQuery = query
        vc.lastDocument = nil
        if isUserProfile{
            vc.navTitle = user.name ?? ""
        }else{
            vc.navTitle = self.navigationItem.title ?? "Trending"
        }
        willPresentAView = true
            navigationController?.pushViewController(vc, animated: true)
            
        }
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
        if let post = posts[indexPath.row] as? Post{
            return post.photoSize
        }else{
            let ad = posts[indexPath.row] as! GADUnifiedNativeAd
            let aspectRatio = ad.mediaContent.aspectRatio
            return CGSize(width: 100 * aspectRatio, height: 140)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case CollectionViewWaterfallElementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ProfileHeader", for: indexPath)
            if isUserProfile{
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                vc = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as? ProfileViewController
                vc?.user = user
                vc?.isCurrentUser = self.isCurrentUser
                vc?.profileDelegate = self
                self.addChild(vc!, in: header)
            }else{
                let storyboard = UIStoryboard(name: "Discover", bundle: nil)
                let vc = storyboard.instantiateViewController(identifier: "CategoriesViewController") as! CategoriesViewController
                self.addChild(vc, in: header)
            }
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
/*
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
*/
extension ExploreViewController : ProfileDelegate{
    func didFinishFetchingRelationship(relationship: Relationship?) {
        if let item = relationship{
            if item.isApproved || !user.isPrivate{
                self.getMorePosts(removeAll : false)
                self.setUpRefresh()
            }else{
                footer?.activityIndicator(show: false)
            }
        }else if !user.isPrivate {
            self.getMorePosts(removeAll : false)
            self.setUpRefresh()
        }else {
            footer?.activityIndicator(show: false)
        }
    }
}

extension ExploreViewController : DZNEmptyDataSetSource, DZNEmptyDataSetDelegate{
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
         if self.isUserProfile{
             if self.vc?.userFollows ?? false || !self.user.isPrivate && !isCurrentUser{
                return UIImage.init(systemName: "photo", withConfiguration: EmptyStateAttributes.shared.config)?.withTintColor(.label)
             }else if self.user.uid == User.shared.uid{
                return UIImage.init(systemName: "plus.app", withConfiguration: EmptyStateAttributes.shared.config)?.withTintColor(.label)
                 
             }else{
                return UIImage.init(systemName: "lock.circle", withConfiguration: EmptyStateAttributes.shared.config)?.withTintColor(.label)
             }
             
         }else{
            return UIImage.init(systemName: "photo", withConfiguration: EmptyStateAttributes.shared.config)?.withTintColor(.label)
         }
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        if self.isUserProfile{
            if self.vc?.userFollows ?? false || !self.user.isPrivate && !isCurrentUser{
               return NSAttributedString(string: "No Posts", attributes: EmptyStateAttributes.shared.title)
            }else if self.user.uid == User.shared.uid{
               return NSAttributedString(string: "You Have No Posts", attributes: EmptyStateAttributes.shared.title)
                
            }else{
               return NSAttributedString(string: "Account Is Private", attributes: EmptyStateAttributes.shared.title)
            }
            
        }else{
            return NSAttributedString(string: "No Posts Avaliable", attributes: EmptyStateAttributes.shared.title)
        }
    }
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        if self.isUserProfile{
            
            if self.vc?.userFollows ?? false || !self.user.isPrivate && !isCurrentUser{
               return NSAttributedString(string: "This user has not posted anything yet", attributes: EmptyStateAttributes.shared.subtitle)
            }else if self.user.uid == User.shared.uid{
                
                return NSAttributedString(string: "Tap the plus button at the bottom to make your first post!", attributes: EmptyStateAttributes.shared.subtitle)
            }else{
               return NSAttributedString(string: "You must follow them to view their content", attributes: EmptyStateAttributes.shared.subtitle)
            }
            
        }else{
            return NSAttributedString(string: "We couldn't find any posts", attributes: EmptyStateAttributes.shared.subtitle)
        }
    }
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if isUserProfile{
            return self.posts.isEmpty
        }else{
        return self.posts.isEmpty && loadedAllPosts
        }
    }

    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
    func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
    
}


extension ExploreViewController : GADAdLoaderDelegate,GADUnifiedNativeAdLoaderDelegate  {
    
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
        adLoader = GADAdLoader(adUnitID: "ca-app-pub-3940256099942544/3986624511",
            rootViewController: self,
            adTypes: [ GADAdLoaderAdType.unifiedNative ],
            options: [mediaOptions])
        adLoader.delegate = self
        adLoader.load(GADRequest())
    }
    
}


