//
//  CommentsViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 1/4/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import FirebaseFirestore
import DeepDiff
import GiphyUISDK
import GiphyCoreSDK
import DZNEmptyDataSet
import SkeletonView

class CommentsViewController: UIViewController {
    
    var commentsDelegate : ExploreViewControllerDelegate?
    
    var comments : [Comment] = [Comment]()
    
    var commentReply : Comment?
    
    @IBOutlet weak var gifButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var textView: UITextView!
    
    var post : Post!
    
    var originalQuery : Query?
    
    var query : Query?
    
    var lastDocument : DocumentSnapshot?
    
    var loadedAllDocuments = false
    
    let refreshControl = UIRefreshControl()
    
    var media : GPHMedia?
    
    var isReplying = false
    
    var navTitle = "Comments"
    
    var commentCount = 0
    
    var footer : UIView?
    private enum Constants {
        static let numberOfCommentsToLoad: Int = 10
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gifButton.roundCorners()
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        
        navigationItem.title = navTitle
        tableView.delegate = self
        tableView.dataSource = self
        tableView.emptyDataSetDelegate = self
        tableView.emptyDataSetSource = self
        textView.delegate = self
        textView.clipsToBounds = false
        textView.layer.cornerRadius = 10
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        self.tableView.sectionHeaderHeight = UITableView.automaticDimension
        self.tableView.estimatedSectionHeaderHeight = 38
        
        textView.addDoneButtonOnKeyboard()
        
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        if isReplying && commentReply != nil{
            originalQuery = db.collection("users").document(post.originalCreatorID).collection("posts").document(post.originalPostID).collection("comments").document(commentReply!.commentID).collection("replies").order(by: "creationDate", descending: true).limit(to: Constants.numberOfCommentsToLoad)
            

            
        }else{
            if originalQuery == nil{
                originalQuery = db.collection("users").document(post.originalCreatorID).collection("posts").document(post.originalPostID).collection("comments").order(by: "creationDate", descending : true).limit(to: Constants.numberOfCommentsToLoad)
            }
        }
    
        getComments(deleteAll: false)
        
        if post.postID.isEmpty || post.originalPostID.isEmpty{
            navigationController?.popViewController(animated: true)
        }
        // Do any additional setup after loading the view.
    }
    
    
    func getComments(deleteAll : Bool){
        query = self.originalQuery
        
        if let doc = self.lastDocument{
            query = query?.start(afterDocument: doc)
        }
        
        query?.getDocuments { (snapshot, error) in
            if error == nil{
                let old = self.comments
                var newItems = self.comments
                if deleteAll{
                    newItems.removeAll()
                }
                for document in snapshot!.documents{
                    let comment = Comment(document: document)
                    if !newItems.contains(comment){
                    newItems.insert(comment, at: 0)
                    }
                    self.lastDocument = document
                }
                if snapshot!.documents.count < Constants.numberOfCommentsToLoad{
                    self.loadedAllDocuments = true
                }
                let changes = diff(old: old, new: newItems)
                self.tableView.reload(changes: changes, section: 0, updateData: {
                    self.comments = newItems
                    self.tableView.reloadEmptyDataSet()
                })
                self.refreshControl.endRefreshing()
                self.footer?.activityIndicator(show: false)
            }else{
                print(error!.localizedDescription)
            }
        }
    
    }
    
    @objc func refreshData(){
       lastDocument = nil
       loadedAllDocuments = false
        refreshControl.beginRefreshing()
        getComments(deleteAll: true)
    }
    
    
    @IBAction func sendButtonPressed(_ sender: Any) {
        guard let text = textView.text else { return }
        
        textView.text = ""
        
        ProgressHUD.show("Sending...")
        var docRef = db.collection("users").document(post.originalCreatorID).collection("posts").document(post.originalPostID).collection("comments").document()
        if isReplying && commentReply != nil{
            docRef = db.collection("users").document(post.originalCreatorID).collection("posts").document(post.originalPostID).collection("comments").document(commentReply!.commentID).collection("replies").document()
        }
        let comment = Comment(text: text, commentID: docRef.documentID, post: self.post, media: self.media, reply : commentReply)
        docRef.setData(comment.representation) { (error) in
            if error == nil{
                ProgressHUD.dismiss()
                let old = self.comments
                var newItems = self.comments
                newItems.append(comment)
                let changes = diff(old: old, new: newItems)
                self.tableView.reload(changes: changes, section: 0, updateData: {
                    self.comments = newItems
                    self.tableView.reloadEmptyDataSet()
                })
                self.media = nil
                self.gifButton.setImage(nil, for: .normal)

            }else{
                ProgressHUD.showError("Error")
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

extension CommentsViewController : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentsTableViewCell", for: indexPath) as! CommentsTableViewCell
        
        var comment = comments[indexPath.row]
        
        cell.usernameLabel.text = comment.creatorUsername
        if self.isReplying || comment.repliesCount <= 0{
            cell.viewRepliesLabel.text = ""
        }else{
        cell.viewRepliesLabel.text = "VIEW \(comment.repliesCount) REPLIES"
        }
        
        cell.captionLabel.text = comment.text
        cell.likeButton.setTitle(String(comment.likes.count), for: .normal)
        
        var height = cell.gifView.frame.width * (1/comment.aspectRatio)
        if height > 300{
            height = 300
        }
        cell.gifViewHeight.constant = height
        cell.setGifMediaView(comment: comment)
        
        let gradient = SkeletonGradient(baseColor: UIColor.secondarySystemBackground)
        cell.profilePictureView.showAnimatedGradientSkeleton(usingGradient: gradient)
        DispatchQueue.main.async {
            cell.profilePictureView.kf.setImage(with: URL(string: comment.photoURL)) { (result) in
                cell.profilePictureView.stopSkeletonAnimation()
                cell.profilePictureView.hideSkeleton(reloadDataAfter: false, transition: .crossDissolve(0.2))
                cell.profilePictureView.layer.cornerRadius = cell.profilePictureView.frame.height/2
            }
        }
        cell.profilePictureView.clipsToBounds = true
        cell.profilePictureView.layer.cornerRadius = cell.profilePictureView.frame.height/2
        cell.dateLabel.text = comment.creationDate.getElapsedInterval()
        
        
        
        cell.setUpGestures()
        
        if comment.likes.contains(User.shared.uid ?? ""){
            cell.setLikedState()
        }else{
            cell.setUnLikedState()
        }
        
        
        cell.likeTapAction = {
        () in
            var docRef = db.collection("users").document(comment.postCreatorID).collection("posts").document(comment.postID).collection("comments").document(comment.commentID).collection("likes").document(User.shared.uid!)
            
            if self.isReplying && self.commentReply != nil{
                docRef =  db.collection("users").document(self.post.originalCreatorID).collection("posts").document(self.post.originalPostID).collection("comments").document(self.commentReply!.commentID).collection("replies").document(comment.commentID).collection("likes").document(User.shared.uid!)
            }
            cell.likeButton.isEnabled = false
            guard let uid = User.shared.uid else { return }
            if comment.likes.contains(uid){
                cell.setUnLikedState()
                comment.likes.removeAll { (id) -> Bool in
                    return uid == id
                }
                self.replaceComment(comment: comment)
                docRef.delete() { (error) in
                if error == nil{
                cell.likeButton.isEnabled = true
                }else{
                    print("here was an error \(error!)")
                    }
            }
            }else{
            cell.setLikedState()
            comment.likes.append(uid)
                self.replaceComment(comment: comment)
             let like = CommentLike(commentID: comment.commentID)
                docRef.setData(like.representation) { (error) in
                    if error == nil{
                    cell.likeButton.isEnabled = true
                    }else{
                        print("there was an error \(error!)")
                }
                }
            }
            cell.likeButton.setTitle(String(comment.likes.count), for: .normal)
        }
        
        cell.profileTapAction = {
        () in
            let docRef = db.collection("users").document(comment.creatorID)
            docRef.getDocument { (snapshot, error) in
                if error == nil{
                    let user = Account()
                    user.convertFromDocument(dictionary: snapshot!)
                    let storyboard = UIStoryboard(name: "Discover", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "ExploreViewController") as! ExploreViewController
                    vc.user = user
                    vc.isUserProfile = true
                    self.navigationController?.pushViewController(vc, animated: true)
                    
                }
            }
        }
        
        cell.moreTapAction = {
        () in
            let actionViewController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            actionViewController.popoverPresentationController?.sourceView = cell.contentView
            actionViewController.popoverPresentationController?.sourceRect = cell.moreButton.frame
            if comment.creatorID == User.shared.uid{
                actionViewController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
                    var docRef = db.collection("users").document(comment.postCreatorID).collection("posts").document(comment.postID).collection("comments").document(comment.commentID)
                    
                    if self.isReplying && self.commentReply != nil{
                        docRef =  db.collection("users").document(self.post.originalCreatorID).collection("posts").document(self.post.originalPostID).collection("comments").document(self.commentReply!.commentID).collection("replies").document(comment.commentID)
                    }
                    
                    docRef.delete { (error) in
                        if error == nil{
                            if let index = self.comments.firstIndex(of: comment){
                                self.comments.remove(at: index)
                                tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                                self.tableView.reloadEmptyDataSet()
                            }
                        }else{
                            ProgressHUD.showError("Error")
                        }
                    }
                }))
            }else{
                actionViewController.addAction(UIAlertAction(title: "Report", style: .destructive, handler: { (action) in
                    print("report pressed")
                }))
            }
            actionViewController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (alert) in
                actionViewController.dismiss(animated: true, completion: nil)
            }))
            self.present(actionViewController, animated: true, completion: nil)
        }
        
   
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return UITableView.automaticDimension
        
    }
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
            return 110
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if !isReplying{
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CommentsViewController") as! CommentsViewController
        vc.isReplying = true
        let comment = comments[indexPath.row]
        vc.commentReply = comment
        vc.post = post
        vc.navTitle = "Replies"
        navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == comments.count && !self.loadedAllDocuments{
            self.getComments(deleteAll: false)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if isReplying && commentReply != nil{
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ReplyHeaderViewController") as! ReplyHeaderViewController
            vc.comment = commentReply!
        let header = vc.view
        self.addChild(vc)
        return header
        }else{
            return self.getHeaderView(with: "\(commentCount) Comments", tableView: tableView)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        footer = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        if self.loadedAllDocuments{
            footer?.activityIndicator(show: false)
        }else{
            footer?.activityIndicator(show: true)
        }
        return footer
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 100
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        commentsDelegate?.collectionViewScrolled(scrollView)
    }
    
    func replaceComment(comment : Comment){
        guard let index = self.comments.firstIndex(of: comment) else { return }
        comments.remove(at: index)
        comments.append(comment)
    }
    
    
}

extension  CommentsViewController : UITextViewDelegate{
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.secondaryLabel {
            textView.text = nil
            textView.textColor = UIColor.label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Write a comment..."
            textView.textColor = UIColor.secondaryLabel
        }
    }
    
    
}

extension CommentsViewController : GifDelegate{
    @IBAction func gifButtonPressed(_ sender: Any) {
        let discoverStoryboard = UIStoryboard(name: "Discover", bundle: nil)
        let giphy = discoverStoryboard.instantiateViewController(withIdentifier: "GifViewController") as! GifViewController
        giphy.gifDeleagte = self
        navigationController?.pushViewController(giphy, animated: true)
    }
    
    func didSelectItem(gif: GPHMedia, vc: GifViewController) {
        print("did select giph media")
        self.media = gif
        if let string = gif.url(rendition: .fixedWidth, fileType: .gif), let url = URL(string: string){
            let gradient = SkeletonGradient(baseColor: UIColor.secondarySystemBackground)
            self.gifButton.showAnimatedGradientSkeleton(usingGradient: gradient)
            DispatchQueue.main.async {
                self.gifButton.stopSkeletonAnimation()
                self.gifButton.kf.setImage(with: url, for: .normal) { (result) in
                    self.gifButton.stopSkeletonAnimation()
                    self.gifButton.hideSkeleton(reloadDataAfter: false, transition: .crossDissolve(0.2))
                }
            }
        }
        vc.navigationController?.popViewController(animated: true)
    }
    
    
}


extension CommentsViewController : DZNEmptyDataSetSource, DZNEmptyDataSetDelegate{
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
         return UIImage.init(systemName: "bubble.left.and.bubble.right", withConfiguration: EmptyStateAttributes.shared.config)?.withTintColor(.label)
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "No Comments", attributes: EmptyStateAttributes.shared.title)
    }
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "You can comment gifs, text, or both", attributes: EmptyStateAttributes.shared.subtitle)
    }
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        return self.comments.isEmpty
    }

    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
    func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
    
}
