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
    
    @IBOutlet weak var imageView: VideoIcon!
    
    @IBOutlet weak var commentsStackView: UIStackView!
    @IBOutlet weak var commentsImageView: UIImageView!
    @IBOutlet weak var commentsLabel: UILabel!
    
    @IBOutlet weak var repostsStackView: UIStackView!
    @IBOutlet weak var repostsImageView: UIImageView!
    @IBOutlet weak var repostsLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    
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
        navigationItem.largeTitleDisplayMode = .never
        
        navigationItem.title = "Post"
        imageView.kf.indicatorType = .activity
        DispatchQueue.main.async {
            self.imageView.kf.setImage(with: URL(string: self.post.photoURL))
        }
        imageView.heroID = post.postID
        engagementStackView.heroID = "\(post.postID).engagementStackView"
        caption.heroID = "\(post.postID).caption"
        timeLabel.text = post.publishDate.getElapsedInterval()
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
        view.addGestureRecognizer(panGR)
        
        self.view.layoutIfNeeded()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isHeroEnabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerContainerView.initialize(post: post, shouldPlay: true)
     /*   if player != nil{
        self.player!.play()
        } */
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
       
        if !shouldContinuePlaying
        {
            navigationController?.isHeroEnabled = false
            playerContainerView.pause()
        }else{
             navigationController?.isHeroEnabled = true
        }
    }
    
    @objc func engagementTapped(){
        let vc = CommentsSectionViewController()
        vc.post = self.post
        navigationController?.isHeroEnabled = false
        navigationController?.pushViewController(vc, animated: true)
        
    }

    
    override func handleDismissButton() {
        super.handleDismissButton()
        shouldContinuePlaying = true
    }
    
    @objc func handlePan(gestureRecognizer:UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            shouldContinuePlaying = true
            navigationController?.popViewController(animated: true)
        case .changed:
            
            let translation = gestureRecognizer.translation(in: nil)
            let progress = translation.x / 2.0 / view.bounds.width
            Hero.shared.update(progress)
            Hero.shared.apply(modifiers: [.translate(x: translation.x)], to: self.view)
            break
        default:
            let translation = gestureRecognizer.translation(in: nil)
            let progress = translation.x / 2.0 / view.bounds.width
            if progress + gestureRecognizer.velocity(in: nil).x / view.bounds.width > 0.3 {
                 DispatchQueue.main.async {
                    self.shouldContinuePlaying = true
                           Hero.shared.finish()
                       }
            } else {
                DispatchQueue.main.async {
                    self.shouldContinuePlaying = true
                           Hero.shared.finish()
                       }
            }
        }
        
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
           if scrollView.panGestureRecognizer.translation(in: scrollView).y < 0{
               changeTabBar(hidden: true, animated: true)
           }
           else{
               changeTabBar(hidden: false, animated: true)
           }
       }

       func changeTabBar(hidden:Bool, animated: Bool){
           guard let tabBar = self.tabBarController?.tabBar else { return; }
           if tabBar.isHidden == hidden{ return }
           let frame = tabBar.frame
           let offset = hidden ? frame.size.height : -frame.size.height
           let duration:TimeInterval = (animated ? 0.2 : 0.0)
           tabBar.isHidden = false

           UIView.animate(withDuration: duration, animations: {
               tabBar.frame = frame.offsetBy(dx: 0, dy: offset)
           }, completion: { (true) in
               tabBar.isHidden = hidden
           })
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
