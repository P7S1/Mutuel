//
//  EmailViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 10/23/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import FirebaseFirestore
class EmailViewController: UIViewController {

    @IBOutlet weak var email: UITextField!
    
    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var errorText: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        email.delegate = self
        
        continueButton.roundCorners()
        email.addDoneButtonOnKeyboard()
        
        errorText.text = ""
        email.clearButtonMode = .whileEditing
        // Do any additional setup after loading the view.
    }
    

    @IBAction func continueButtonPressed(_ sender: Any) {
        ProgressHUD.show()
        if email.text?.isEmpty ?? true{
            print("email was empty")
            errorText.text = "Email can't be left blank"
            ProgressHUD.showError("Error")
        }else{
            if isValidEmail(emailStr: email.text!){
                let docRef = db.collection("users")
                
                let query = docRef.whereField("email", isEqualTo: email.text!)
                
                query.getDocuments { (snapshot, error) in
                    if error == nil{
                        if snapshot?.count == 0{
                            User.shared.email = self.email.text
                            self.errorText.text = ""
                            ProgressHUD.dismiss()
                            self.performSegue(withIdentifier: "goToPassword", sender: self)
                        }else{
                            ProgressHUD.showError("Error")
                            self.errorText.text = "Email is already in use"
                        }
                    }else{
                        print("error getting snapshot data: \(String(describing: error))")
                    }
                }
            }else{
                print("invalid emaail")
                errorText.text = "Email is invalid"
                ProgressHUD.showError("Error")
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

extension EmailViewController : UITextFieldDelegate{
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
       return !(string == " ")
    }
}

extension UIViewController{
    func isValidEmail(emailStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: emailStr)
    }
}
