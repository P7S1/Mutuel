//
//  LoginViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 10/23/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
class LoginViewController: UIViewController {
    
    @IBOutlet weak var username: UITextField!
    
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var errorText: UILabel!
    
    @IBOutlet weak var signUpButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.roundCorners()
        username.addDoneButtonOnKeyboard()
        password.addDoneButtonOnKeyboard()
        setDismissButton()
        
        username.clearButtonMode = .whileEditing
        password.clearButtonMode = .whileEditing
        
        errorText.isHidden = true
        
        signUpButton.roundCorners()
        signUpButton.backgroundColor = .systemGray6
        

        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ProgressHUD.dismiss()
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        ProgressHUD.show()
        let _username = username.text!
        signUserIn(login: _username)
    }
    
    @IBAction func signUpButtonPressed(_ sender: Any) {
        let storyboard = UIStoryboard.init(name: "Login", bundle: nil)

        let vc = storyboard.instantiateViewController(withIdentifier: "SignUpViewController") as! SignUpViewController
        
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil) 
    }
    
    
    func signUserIn(login : String){
        print("proceeding to sign in to \(login)")
        Auth.auth().signIn(withEmail: login, password: password.text!) { (result, error) in
            if error == nil{
                print("success signing in")
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "logUserIn"), object: nil)
                appDidLoad = false
            }else{
                self.fail()
                if let errCode = AuthErrorCode(rawValue: error!._code) {
                switch errCode {
                case .invalidEmail:
                        self.errorText.text = "Invalid Email"
                case .wrongPassword:
                        print("Invalid Password")
                    self.errorText.text = "Invalid Password"
                    default:
                        print("Invalid email or password")
                }
            }
        }
        
    }
    }
    
    func fail(){
        ProgressHUD.showError("Error")
        errorText.isHidden = false
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
