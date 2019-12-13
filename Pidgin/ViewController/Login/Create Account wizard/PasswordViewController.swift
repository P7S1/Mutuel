//
//  PasswordViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 10/23/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
class PasswordViewController: UIViewController {
    
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var confirmPassword: UITextField!
    
    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var errorText: UILabel!
    
    @IBOutlet weak var passwordMustIncldue: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        password.clearButtonMode = .whileEditing
        confirmPassword.clearButtonMode = .whileEditing
        password.delegate = self
        confirmPassword.delegate = self
        
        continueButton.roundCorners()
        password.addDoneButtonOnKeyboard()
        confirmPassword.addDoneButtonOnKeyboard()
        
        errorText.text = ""
        
        passwordMustIncldue.text = "Password must include: \n *At least 8 characters \n *At least one digit \n *At least one lowercase \n *At least one uppercase"

        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ProgressHUD.dismiss()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        userListener?.remove()
    }
    
    @IBAction func continueButtonPressed(_ sender: Any) {
        if !(password.text?.isEmpty ?? true){
            if password.text!.count > 7{
        if isValidPassword(testStr: password.text){
            if password.text == confirmPassword.text{
                User.shared.password = password.text
                print("password success, creating account")
                createAccount()
            }else{
                ProgressHUD.showError("Error")
                errorText.text = "Passwords do not match"
            }
        }else{
            ProgressHUD.showError("Error")
            errorText.text = "Password doesn't meet criteria"
        }
            }else{
                ProgressHUD.showError("Error")
                errorText.text = "Password is too short"
            }
        }else{
            ProgressHUD.showError("Error")
            errorText.text = "Password can't be left blank"
        }
    }
    
    func isValidPassword(testStr:String?) -> Bool {
        guard testStr != nil else { return false }
        // at least one uppercase,
        // at least one digit
        // at least one lowercase
        // 8 characters total
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", "(?=.*[A-Z])(?=.*[0-9])(?=.*[a-z]).{8,}")
        return passwordTest.evaluate(with: testStr)
    }
    
    func createAccount(){
        ProgressHUD.show()
        Auth.auth().createUser(withEmail: User.shared.email!, password: User.shared.password!) { (result, error) in
            if error == nil{
                User.shared.uid = result?.user.uid
                
                (db.collection("users")).document((result?.user.uid)!).setData([
                    "name": User.shared.name!,
                    "username": User.shared.username!,
                    "email": User.shared.email!,
                    "birthday" : User.shared.birthday!
                ]) { err in
                    if let err = err {
                        print("Error writing document: \(err)")
                    } else {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "logUserIn"), object: nil)
                        appDidLoad = false
                        print("Document successfully written!")
                    }
                }
            }else{
                ProgressHUD.showError("Error, try again later")
                print("Error creating account: \(error!))")
            }
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

extension PasswordViewController : UITextFieldDelegate{
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
       return !(string == " ")
    }
}
