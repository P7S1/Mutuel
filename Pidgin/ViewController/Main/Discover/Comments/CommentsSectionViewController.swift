//
//  CommentsSectionViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 1/25/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit

class CommentsSectionViewController: UIViewController, UIScrollViewDelegate {
    
    
    var latestCommentsVC : CommentsViewController!
    
    var topCommentsVC : CommentsViewController!
    
    var post : Post!
    
    private enum Constants {
        static let segmentedControlHeight: CGFloat = 35
        static let underlineViewColor: UIColor = .systemPink
        static let underlineViewHeight: CGFloat = 2
    }
    
    private lazy var segmentedControlContainerView: UIView = {
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height:Constants.segmentedControlHeight ))
        containerView.backgroundColor = .systemBackground
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.isUserInteractionEnabled = true
        return containerView
    }()
    
    private lazy var segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(frame: CGRect(x: 00, y: 0, width: Constants.segmentedControlHeight, height: self.view.bounds.height))
        segmentedControl.isUserInteractionEnabled = true
        // Remove background and divider color
        segmentedControl.backgroundColor = .clear
        segmentedControl.tintColor = .clear
        segmentedControl.selectedSegmentTintColor  = .clear
        fixBackgroundSegmentControl(segmentedControl)
        // Append segments
        segmentedControl.insertSegment(withTitle: "Top", at: 0, animated: true)
        segmentedControl.insertSegment(withTitle: "Recent", at: 1, animated: true)

        // Select first segment by default
        segmentedControl.selectedSegmentIndex = 0
            
        // Change text color and the font of the NOT selected (normal) segment
        segmentedControl.setTitleTextAttributes([
            NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .semibold)], for: .normal)

        // Change text color and the font of the selected segment
        segmentedControl.setTitleTextAttributes([
            NSAttributedString.Key.foregroundColor: UIColor.label,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .bold)], for: .selected)

        // Set up event handler to get notified when the selected segment changes
        segmentedControl.addTarget(self, action: #selector(indexChanged(_:)), for: .valueChanged)
        // Return false because we will set the constraints with Auto Layout
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        return segmentedControl
    }()
    
    private lazy var bottomUnderlineView: UIView = {
        let underlineView = UIView()
        underlineView.isUserInteractionEnabled = true
        underlineView.backgroundColor = Constants.underlineViewColor
        underlineView.translatesAutoresizingMaskIntoConstraints = false
        return underlineView
    }()
    
    private lazy var leadingDistanceConstraint: NSLayoutConstraint = {
        return bottomUnderlineView.leftAnchor.constraint(equalTo: segmentedControl.leftAnchor)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Comments"
        
        segmentedControlContainerView.addSubview(segmentedControl)
        segmentedControlContainerView.addSubview(bottomUnderlineView)
        addSegmentedControlConstraints()
        
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
        let vc1 = storyboard.instantiateViewController(withIdentifier: "CommentsViewController") as! CommentsViewController
        
        latestCommentsVC = vc1
        
        vc1.commentsDelegate = self
        vc1.post = self.post
        let vc2 = storyboard.instantiateViewController(withIdentifier: "CommentsViewController") as! CommentsViewController
        
        topCommentsVC = vc2
        vc2.post = self.post
        vc2.commentsDelegate = self
        
        indexChanged(segmentedControl)

        // Do any additional setup after loading the view.
    }
    
    
    
    @objc func indexChanged(_ sender: UISegmentedControl) {
        changeSegmentedControlLinePosition()
        switch sender.selectedSegmentIndex{
            case 0:
                print("Discover")
                latestCommentsVC.removeFromParent()
                latestCommentsVC.view.removeFromSuperview()
                latestCommentsVC.didMove(toParent: nil)
                self.addChild(topCommentsVC)
                self.view.addSubview(topCommentsVC.view)
                addConstraints(view: topCommentsVC.view)
                topCommentsVC.didMove(toParent: self)
            case 1:
                print("Following")
                topCommentsVC.removeFromParent()
                topCommentsVC.view.removeFromSuperview()
                topCommentsVC.didMove(toParent: nil)
                self.addChild(latestCommentsVC)
            self.view.addSubview(latestCommentsVC.view)
                addConstraints(view: latestCommentsVC.view)
                latestCommentsVC.didMove(toParent: self)
            default:
                break
            }
    }
    
    func addSegmentedControlConstraints(){
        self.view.addSubview(segmentedControlContainerView)
    let safeLayoutGuide = self.view.safeAreaLayoutGuide
     NSLayoutConstraint.activate([
         segmentedControlContainerView.topAnchor.constraint(equalTo: safeLayoutGuide.topAnchor),
         segmentedControlContainerView.leadingAnchor.constraint(equalTo: safeLayoutGuide.leadingAnchor),
         segmentedControlContainerView.widthAnchor.constraint(equalTo: safeLayoutGuide.widthAnchor),
         segmentedControlContainerView.heightAnchor.constraint(equalToConstant: Constants.segmentedControlHeight)
         ])
     
     // Constrain the segmented control to the container view
     NSLayoutConstraint.activate([
         segmentedControl.topAnchor.constraint(equalTo: segmentedControlContainerView.topAnchor),
         segmentedControl.leadingAnchor.constraint(equalTo: segmentedControlContainerView.leadingAnchor),
         segmentedControl.centerXAnchor.constraint(equalTo: segmentedControlContainerView.centerXAnchor),
         segmentedControl.centerYAnchor.constraint(equalTo: segmentedControlContainerView.centerYAnchor)
         ])

     // Constrain the underline view relative to the segmented control
     NSLayoutConstraint.activate([
         bottomUnderlineView.bottomAnchor.constraint(equalTo: segmentedControl.bottomAnchor),
         bottomUnderlineView.heightAnchor.constraint(equalToConstant: Constants.underlineViewHeight),
         leadingDistanceConstraint,
         bottomUnderlineView.widthAnchor.constraint(equalTo: segmentedControl.widthAnchor, multiplier: 1 / CGFloat(segmentedControl.numberOfSegments))
         ])
    }
    
    func addConstraints(view : UIView){
        view.frame = self.view.bounds
        view.translatesAutoresizingMaskIntoConstraints = false
        view.topAnchor.constraint(equalTo: self.segmentedControlContainerView.bottomAnchor).isActive = true
        view.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    }
    
    private func changeSegmentedControlLinePosition() {
        let segmentIndex = CGFloat(segmentedControl.selectedSegmentIndex)
        let segmentWidth = segmentedControl.frame.width / CGFloat(segmentedControl.numberOfSegments)
        let leadingDistance = segmentWidth * segmentIndex
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            self?.leadingDistanceConstraint.constant = leadingDistance
            self?.view.layoutIfNeeded()
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

extension CommentsSectionViewController : ExploreViewControllerDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
      
    }
    func collectionViewScrolled(_ scrollView: UIScrollView) {
        self.scrollViewDidScroll(scrollView)
    }
    
    
}


