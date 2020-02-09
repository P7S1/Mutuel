//
//  ChangePasswordViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 1/20/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import Eureka
import FirebaseAuth
class ChangePasswordViewController: FormViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        NotificationCenter.default.addObserver(self, selector: #selector(presentNotification), name: NSNotification.Name(rawValue: "presentNotification"), object: nil)
        
        saveChangesButton()
        navigationItem.title = "New Password"
        form +++ Section("Create a new password")
            <<< PasswordRow("password"){
                row in
            row.title = "Password"
        }
        
        form +++ Section("Confirm your new password")
        <<< PasswordRow("confirmPassword"){
                row in
            row.title = "Confirm"
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Auth.auth().currentUser != nil {
            print("user is signed in")
        } else {
            print("user is not signed in")
            returnToLoginScreen()
        }
    }
    
    func saveChangesButton(){
        let settings = UIButton.init(type: .custom)
        settings.setTitle("Save", for: .normal)
        settings.setTitleColor(.systemPink, for: .normal)
        settings.addTarget(self, action:#selector(handleSaveButton), for:.touchUpInside)
        let settingsButton = UIBarButtonItem.init(customView: settings)
        navigationItem.rightBarButtonItems = [settingsButton]
    }
    
    @objc func handleSaveButton(){
        let formvalues = self.form.values()
        ProgressHUD.show()
        guard let password = formvalues["password"] as? String else {
            ProgressHUD.showError("Password can't left be empty")
            return }
        guard let confirmPassowrd = formvalues["confirmPassword"] as? String else {
            ProgressHUD.showError("Confirm password can't be left empty")
            return }
            
            if password == confirmPassowrd{
            Auth.auth().currentUser?.updatePassword(to: password, completion: { (error) in
                if error == nil{
                    print("password successful")
                    ProgressHUD.showSuccess("password changed")
                    self.navigationController?.popToRootViewController(animated: true)
                }else{
                    print("there was a error \(error!.localizedDescription)")
                    ProgressHUD.showError("Password error")
                    if let errCode = AuthErrorCode(rawValue: error!._code) {
                        switch errCode {
                        case .weakPassword:
                            ProgressHUD.showError("Password too weak")
                        case .wrongPassword:
                                print("Invalid Password")
                                ProgressHUD.showError("Invalid password")
                            default:
                                ProgressHUD.showError("Invalid password")
                                print("Invalid email or password")
                        }
                    }
                }
            })
            }else{
                ProgressHUD.showError("Passwords do not match")
            }
            
       
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
