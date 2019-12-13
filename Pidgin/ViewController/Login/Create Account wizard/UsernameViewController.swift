//
//  UsernameViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 10/23/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import FirebaseFirestore
class UsernameViewController: UIViewController{

    @IBOutlet weak var username: UITextField!
    
    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var errorText: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        errorText.text = ""
        username.delegate = self
        continueButton.roundCorners()
        username.addDoneButtonOnKeyboard()
        username.clearButtonMode = .whileEditing
        // Do any additional setup after loading the view.
    }
    
    @IBAction func continueButtonPressed(_ sender: Any) {
        ProgressHUD.show()
        if username.text?.isEmpty ?? true{
            print("username is empty")
            errorText.text = "Username can't be left blank"
        }else{
            if username.text!.count > 2{
                if !username.text!.containsSpecialCharacter{
                    let docRef = db.collection("users")
                    
                    let query = docRef.whereField("username", isEqualTo: username.text!)
                    
                    query.getDocuments { (snapshot, error) in
                        if error == nil{
                            if snapshot?.count == 0{
                                User.shared.username = self.username.text
                                self.errorText.text = ""
                                ProgressHUD.dismiss()
                                self.performSegue(withIdentifier: "goToEmail", sender: self)
                            }else{
                                ProgressHUD.showError("Error")
                                self.errorText.text = "Username is already in use"
                            }
                        }else{
                            ProgressHUD.showError()
                            print("error getting snapshot data: \(String(describing: error))")
                        }
                    }
                }else{
                    ProgressHUD.showError("Error")
                    errorText.text = "Only letters and numbers are allowed"
                }
    
            }else{
                ProgressHUD.showError("Error")
                errorText.text = "Username must be atleast 3 characters"
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

extension UsernameViewController : UITextFieldDelegate{
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
       return !(string == " ")
    }
}

extension String {
   var containsSpecialCharacter: Bool {
      let regex = ".*[^A-Za-z0-9].*"
      let testString = NSPredicate(format:"SELF MATCHES %@", regex)
      return testString.evaluate(with: self)
   }
}
