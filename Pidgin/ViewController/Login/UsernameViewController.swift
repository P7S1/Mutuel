//
//  UsernameViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 1/8/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
protocol UsernameViewControllerDelegate {
    func didFinishSettingUsername(user : User)
}
class UsernameViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var usernameErrorLabel: UILabel!
    
    @IBOutlet weak var displaynameTextField: UITextField!
    @IBOutlet weak var displayNameErrorLabel: UILabel!
    
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    let allowedCharacters = CharacterSet(charactersIn:"0123456789abcdefghijklmnopqrstuvxyz_.").inverted
    
    var usernameDelegate : UsernameViewControllerDelegate?
    
    var user = User()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Finish setting up your account"
        usernameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        displaynameTextField.addDoneButtonOnKeyboard()
        usernameTextField.addDoneButtonOnKeyboard()
        usernameTextField.clearButtonMode = .whileEditing
        displaynameTextField.clearButtonMode = .whileEditing
        
        usernameTextField.delegate = self
        
        continueButton.roundCorners()
        clearErrorLabels()
        // Do any additional setup after loading the
    }
    
    @IBAction func continueButtonPressed(_ sender: Any) {
        clearErrorLabels()
        guard let username = usernameTextField.text else {
            return
        }
        if username.count >= 3 && username.count <= 16 {
            if !(displaynameTextField.text?.isEmpty ?? true){
            ProgressHUD.show()
            let query = db.collection("users").whereField("username", isEqualTo: username)
            query.getDocuments { (snapshot, error) in
                if error == nil{
                    if snapshot?.count == 0{
                        self.user = User.shared
                        self.user.birthday = self.datePicker.date
                        self.user.name = self.displaynameTextField.text
                        self.user.username = username
                        self.user.uid = Auth.auth().currentUser?.uid
                        self.user.email = Auth.auth().currentUser?.email
                        let docRef = db.collection("users").document(Auth.auth().currentUser!.uid)
                        docRef.setData(self.user.representation, merge: true) { (error) in
                            if error == nil{
                                ProgressHUD.dismiss()
                                appDidLoad = false
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "logUserIn"), object: nil)
                            }else{
                                ProgressHUD.showError("Error")
                                print("there was an error: \(error!.localizedDescription)")
                            }
                        }
                    }else{
                      ProgressHUD.showError("Error")
                        self.usernameErrorLabel.text = "Username is already in use"
                    }
                }else{
                    ProgressHUD.showError("Error")
                    print("ther was an error \(error!.localizedDescription)")
                }
            }
            }else{
                displayNameErrorLabel.text = "Display name can't be left empty"
            }
        }else{
            if username.count >= 3{
            usernameErrorLabel.text = "Must be shorter than 17 characters"
            }else{
             usernameErrorLabel.text = "Must be longer than 2 characters"
            }
        }
    }
    
    func clearErrorLabels(){
        usernameErrorLabel.text = ""
        displayNameErrorLabel.text = ""
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let components = string.components(separatedBy: allowedCharacters)
        let filtered = components.joined(separator: "")
        
        if string == filtered {
            
            return true

        } else {
            
            return false
        }
    }
    @objc func textFieldDidChange(textField: UITextField) {
        textField.text = textField.text?.lowercased()
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
