//
//  ExploreViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 12/27/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import CHTCollectionViewWaterfallLayout
import DeepDiff
import AVKit
public protocol ExploreViewControllerDelegate {
   func collectionViewScrolled(_ scrollView: UIScrollView)
}
class ExploreViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var posts = [Post]()
    
    var exploreDelegate : ExploreViewControllerDelegate?
    
     var adjustInsets = false
    
    var activityIndicator : UIActivityIndicatorView!
    
    var willPresentAView = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.isHeroEnabled = true
        collectionView.delegate = self
        collectionView.dataSource = self
        
        self.activityIndicator = UIActivityIndicatorView(style: .medium)
        self.activityIndicator.frame = CGRect(x: 0, y: 0, width: 46, height: 46)
        self.activityIndicator.hidesWhenStopped = true
        
        collectionView.addSubview(activityIndicator)
        
        activityIndicator.startAnimating()
        
        setUpCollectionView()
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        if adjustInsets{
            
        collectionView.contentInset = UIEdgeInsets(top: 56, left: 0, bottom: 0, right: 0)
        }
        let docRef = db.collectionGroup("posts").order(by: "publishDate", descending: true)
        

        
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
                print("there was an error \(error!)")
            }
        }
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isHeroEnabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isHeroEnabled = false
    }
    
    func setUpCollectionView(){
       let layout = CHTCollectionViewWaterfallLayout()
        
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
        
        // Change individual layout attributes for the spacing between cells
        layout.minimumColumnSpacing = 8
        layout.minimumInteritemSpacing = 8
        
        // Collection view attributes
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.alwaysBounceVertical = true
        
        // Add the waterfall layout to your collection view
        collectionView.collectionViewLayout = layout
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

extension ExploreViewController: UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExploreCollectionViewCell", for: indexPath) as! ExploreCollectionViewCell
        cell.imageView.clipsToBounds = true
        cell.imageView.layer.cornerRadius = 10
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.imageView.heroID = posts[indexPath.row].postID
        cell.imageView.kf.setImage(with: URL(string: posts[indexPath.row].photoURL), placeholder: UIImage(named: "group"))
        cell.playButton.isHidden = !(posts[indexPath.row].isVideo)
        cell.playButton.heroID = "\(posts[indexPath.row].postID).playButton"
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
         let vc = storyboard.instantiateViewController(withIdentifier: "FollowingViewController") as! FollowingViewController
        vc.shouldQuery = false
         vc.posts = posts
        vc.indexPath = indexPath
        vc.postDelegate = self
        willPresentAView = true
         navigationController?.pushViewController(vc, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        exploreDelegate?.collectionViewScrolled(scrollView)
    }

    
    
}

extension ExploreViewController : CHTCollectionViewDelegateWaterfallLayout{
    func collectionView(_ collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAt indexPath: IndexPath!) -> CGSize {
        return posts[indexPath.row].photoSize
    }
    
}

extension ExploreViewController : PostViewDelegate{
    func preparePostsFor(indexPath: IndexPath, posts: [Post]) {
        self.collectionView.performBatchUpdates({
            let changes = diff(old: self.posts, new: posts)
            self.collectionView.reload(changes: changes, section: 0, updateData: {
                self.posts = posts
                self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            })
        })
    
    }
    
    
}

