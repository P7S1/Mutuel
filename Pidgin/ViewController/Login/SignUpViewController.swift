//
//  SignUpViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 1/8/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import FirebaseAuth
class SignUpViewController: UIViewController, UsernameViewControllerDelegate {
    

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var emailErrorLabel: UILabel!
    
    @IBOutlet weak var PasswordTextField: UITextField!
    @IBOutlet weak var passwordErrorLabel: UILabel!
    
    @IBOutlet weak var confirmPassowrdTextField: UITextField!
    @IBOutlet weak var confirmPasswordErrorLabel: UILabel!
    
    @IBOutlet weak var continueButton: UIButton!
    
    var shouldContinue = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Sign Up"
        clearErrorLabels()
        setDismissButton()
        continueButton.roundCorners()
        confirmPassowrdTextField.addDoneButtonOnKeyboard()
        PasswordTextField.addDoneButtonOnKeyboard()
        emailTextField.addDoneButtonOnKeyboard()
        emailTextField.clearButtonMode = .whileEditing
        PasswordTextField.clearButtonMode = .whileEditing
        confirmPassowrdTextField.clearButtonMode = .whileEditing
        // Do any additional setup after loading the view.
    }
    
    @IBAction func continueButtonPressed(_ sender: Any) {
        clearErrorLabels()
        if shouldContinue{
            let storyboard = UIStoryboard.init(name: "Login", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "UsernameViewController") as! UsernameViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }else{
            ProgressHUD.show()
        if PasswordTextField.text == confirmPassowrdTextField.text{
            Auth.auth().createUser(withEmail: emailTextField.text ?? "",
                                   password: PasswordTextField.text ?? "") { (result, error) in
                if error == nil{
                    ProgressHUD.dismiss()
                    self.confirmPassowrdTextField.isEnabled = false
                    self.PasswordTextField.isEnabled = false
                    self.emailTextField.isEnabled = false
                    self.shouldContinue = true
                    self.navigationItem.leftBarButtonItems = []
                    let storyboard = UIStoryboard.init(name: "Login", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "UsernameViewController") as! UsernameViewController
                    self.navigationController?.pushViewController(vc, animated: true)
                }else{
                    ProgressHUD.showError("Error")
                    if let errCode = AuthErrorCode(rawValue: error!._code) {
                        switch errCode {
                        case .invalidEmail:
                            self.emailErrorLabel.text = "Invalid email"
                        case .wrongPassword:
                                print("Invalid Password")
                                self.passwordErrorLabel.text = "Invalid password"
                        case .emailAlreadyInUse:
                            print("email in use")
                            self.emailErrorLabel.text = "Email already in use"
                        case .weakPassword:
                            print("Invalid Password")
                            self.passwordErrorLabel.text = "Password is too weak"
                            default:
                                self.passwordErrorLabel.text = "Invalid email or password"
                                print("Invalid email or password")
                        }
                    }
                }
            }
        }else{
            ProgressHUD.showError("Error")
           self.confirmPasswordErrorLabel.text = "Passwords do not match"
        }
    }
    }
    
    func didFinishSettingUsername(user: User) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "logUserIn"), object: nil)
        appDidLoad = false
    }
    
    func clearErrorLabels(){
        emailErrorLabel.text = ""
        passwordErrorLabel.text = ""
        confirmPasswordErrorLabel.text = ""
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
