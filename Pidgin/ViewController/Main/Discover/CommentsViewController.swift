//
//  CommentsViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 1/4/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit

class CommentsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        navigationItem.title = "Comments"
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isHeroEnabled = false
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
