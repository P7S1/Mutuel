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
public protocol ExploreViewControllerDelegate {
   func collectionViewScrolled(_ scrollView: UIScrollView)
}
class ExploreViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var posts = [Post]()
    
    var exploreDelegate : ExploreViewControllerDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.isHeroEnabled = true
        collectionView.delegate = self
        collectionView.dataSource = self
        setUpCollectionView()
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
                        self.posts = newItems.shuffled()
                    })
                }, completion: nil)
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
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
         let vc = storyboard.instantiateViewController(withIdentifier: "FollowingViewController") as! FollowingViewController
        vc.shouldQuery = false
         vc.posts = posts
        vc.indexPath = indexPath
        vc.postDelegate = self
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

