//
//  ForgotPasswordViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 1/20/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import FirebaseAuth
class ForgotPasswordViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var errorText: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        continueButton.roundCorners()
        errorText.text = ""
        textField.delegate = self
        textField.addDoneButtonOnKeyboard()
        navigationItem.title = "Forgot Password"
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        // Do any additional setup after loading the view.
    }
    
    @IBAction func continueButtonPressed(_ sender: Any) {
        ProgressHUD.show()
        Auth.auth().sendPasswordReset(withEmail: textField.text ?? "") { error in
            if error == nil{
                ProgressHUD.dismiss()
                let storyboard = UIStoryboard.init(name: "Login", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "PasswordResetEmailViewController") as! PasswordResetEmailViewController
                vc.email = self.textField.text ?? ""
                self.navigationController?.pushViewController(vc, animated: true)
            }else{
                print("error : \(error!.localizedDescription)")
                ProgressHUD.showError("Error")
                
                self.errorText.text = "Invalid email"
                }
            }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        errorText.text = ""
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
