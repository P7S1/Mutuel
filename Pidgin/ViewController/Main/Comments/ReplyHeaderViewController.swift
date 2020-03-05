//
//  ReplyHeaderViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 2/11/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit

class ReplyHeaderViewController: UIViewController {
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var replyingToLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    var comment : Comment!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profilePicture.kf.setImage(with: URL(string: comment.photoURL))
        profilePicture.layer.cornerRadius = profilePicture.frame.height/2
        commentLabel.text = comment.text
        timeLabel.text = comment.creationDate.getElapsedInterval()
        replyingToLabel.text = "Replying to \(comment.creatorUsername)"
        // Do any additional setup after loading the view.
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
