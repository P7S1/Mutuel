//
//  PostViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 12/30/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import Hero
class PostViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var contentView: UIView!
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var commentsStackView: UIStackView!
    @IBOutlet weak var commentsImageView: UIImageView!
    @IBOutlet weak var commentsLabel: UILabel!
    
    @IBOutlet weak var repostsStackView: UIStackView!
    @IBOutlet weak var repostsImageView: UIImageView!
    @IBOutlet weak var repostsLabel: UILabel!
    
    @IBOutlet weak var caption: UILabel!
    
    @IBOutlet weak var engagementStackView: UIStackView!
    
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    
    var post : Post!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        self.isHeroEnabled = true
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = "Post"

        imageView.kf.setImage(with: URL(string: post.photoURL))
        imageView.heroID = post.postID
        engagementStackView.heroID = "\(post.postID).engagementStackView"
        caption.heroID = "\(post.postID).caption"
        
        scrollView.alwaysBounceVertical = true
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
        
        let scale = UIScreen.main.bounds.width / post.photoSize.width
        imageViewHeightConstraint.constant = post.photoSize.height * scale
        
        caption.text = post.caption
        commentsLabel.text = "\(post.commentsCount) comments"
        repostsLabel.text = "\(post.repostsCount) reposts"
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(engagementTapped))
        engagementStackView.addGestureRecognizer(tap)
        self.view.layoutIfNeeded()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isHeroEnabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.isHeroEnabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isHeroEnabled = false
    }
    
    override func viewDidLayoutSubviews() {
        scrollView.contentSize = contentView.frame.size
    }
    
    @objc func engagementTapped(){
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CommentsViewController") as! CommentsViewController
        
        navigationController?.pushViewController(vc, animated: true)
        
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
