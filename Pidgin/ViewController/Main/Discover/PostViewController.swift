//
//  PostViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 12/30/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import Hero
import AVKit
import Lightbox
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
    
    var panGR: UIPanGestureRecognizer!
    
    
    @IBOutlet weak var playerContainerView: PlayerContainerView!
    
    var shouldContinuePlaying = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        scrollView.delegate = self
        self.isHeroEnabled = true
        navigationItem.largeTitleDisplayMode = .never
        self.view.isHeroEnabled = true
        self.view.heroID = "\(post.postID).view"
        HeroAutolayoutFixPlugin.enable()
        self.playerContainerView.heroModifiers = [.useNoSnapshot, .autolayout]
        self.imageView.heroModifiers = [.useNoSnapshot, .autolayout]
        let titleView = UIImageView(frame: CGRect(x: 0, y: 0, width: 38, height: 38))
        let config = UIImage.SymbolConfiguration(pointSize: 21, weight: .medium)
        titleView.image = UIImage(systemName: "chevron.down", withConfiguration: config)
        titleView.contentMode = .scaleAspectFit
        titleView.tintColor = .secondaryLabel
        navigationItem.titleView? = titleView
        
        self.setDismissButton()

        imageView.kf.setImage(with: URL(string: post.photoURL))
        imageView.heroID = post.postID
        engagementStackView.heroID = "\(post.postID).engagementStackView"
        caption.heroID = "\(post.postID).caption"
        
        scrollView.alwaysBounceVertical = true
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 32, right: 0)
        
        let scale = UIScreen.main.bounds.width / post.photoSize.width
        imageViewHeightConstraint.constant = post.photoSize.height * scale
        
        caption.text = post.caption
        commentsLabel.text = "\(post.commentsCount)"
        repostsLabel.text = "\(post.repostsCount)"
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(engagementTapped))
        engagementStackView.addGestureRecognizer(tap)
        playerContainerView.heroID = "\(post.postID).player"
        
        if post.isVideo{
            playerContainerView.initialize(post: post, shouldPlay: true)
        }else{
            playerContainerView.isHidden = true
            playerContainerView.pause()
        }
        
        panGR = UIPanGestureRecognizer(target: self,
                  action: #selector(handlePan(gestureRecognizer:)))
        panGR.delegate = self
        scrollView.addGestureRecognizer(panGR)
        
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
        playerContainerView.initialize(post: post, shouldPlay: true)
     /*   if player != nil{
        self.player!.play()
        } */
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !shouldContinuePlaying
        {
            playerContainerView.pause()
        }
        navigationController?.isHeroEnabled = false
    }
    
    @objc func engagementTapped(){
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CommentsViewController") as! CommentsViewController
        
        navigationController?.pushViewController(vc, animated: true)
        
    }

    
    override func handleDismissButton() {
        super.handleDismissButton()
        shouldContinuePlaying = true
    }
    
    @objc func handlePan(gestureRecognizer:UIPanGestureRecognizer) {
        print(gestureRecognizer.velocity(in: self.view).y )
        if gestureRecognizer.velocity(in: self.view).y > 1600{
            self.handleDismissButton()
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
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
