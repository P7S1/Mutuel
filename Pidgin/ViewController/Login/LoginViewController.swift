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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.roundCorners()
        username.addDoneButtonOnKeyboard()
        password.addDoneButtonOnKeyboard()
        setDismissButton()
        
        username.clearButtonMode = .whileEditing
        password.clearButtonMode = .whileEditing
        
        errorText.isHidden = true
        

        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ProgressHUD.dismiss()
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        ProgressHUD.show()
        if username.text?.isEmpty ?? true{
         fail()
        }else{
            if password.text?.isEmpty ?? true{
              fail()
            }else{
                var _username = username.text!
                if !isValidEmail(emailStr: _username){
                print("user decided to use username")
                let docRef = db.collection("users")
                
                let query = docRef.whereField("username", isEqualTo: username.text!)
                
                query.getDocuments { (snapshot, error) in
                    if error == nil{
                        if snapshot?.count == 0{
                            self.fail()
                        }else{
                        for document in snapshot!.documents{
                             _username = document.get("email") as! String
                            print("found email for username: \(_username)")
                            self.signUserIn(login: _username)
                        }
                        }
                    }else{
                        self.fail()
                        print("error getting snapshot data: \(String(describing: error))")
                    }
                }
                }else{
                    signUserIn(login: _username)
                }
            }
        }
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
                print("Error signing in : \(String(describing: error))")
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
