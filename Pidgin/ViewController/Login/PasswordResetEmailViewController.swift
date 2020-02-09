//
//  PasswordResetEmailViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 1/20/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import FirebaseAuth
class PasswordResetEmailViewController: UIViewController {

    @IBOutlet weak var resendEmailButton: UIButton!
    
    @IBOutlet weak var messageLabel: UILabel!
    
    var email = ""
    
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        
        resendEmailButton.backgroundColor = .systemGray6
        resendEmailButton.roundCorners()
        loginButton.roundCorners()
        messageLabel.text = "We've sent a password reset email to \(email)"
        // Do any additional setup after loading the view.
    }
    
    @IBAction func resendEmailButton(_ sender: Any) {
        ProgressHUD.show()
        Auth.auth().sendPasswordReset(withEmail: email) { error in
        if error == nil{
            ProgressHUD.showSuccess("Email Resent")
        }else{
            print("error : \(error!.localizedDescription)")
            ProgressHUD.showError("Error")
            }
        }
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
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
