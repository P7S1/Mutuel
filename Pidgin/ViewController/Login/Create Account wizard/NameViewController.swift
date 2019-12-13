//
//  NameViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 10/23/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit

class NameViewController: UIViewController {

    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var firstName: UITextField!
    
    @IBOutlet weak var errorText: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        firstName.addDoneButtonOnKeyboard()
        
        continueButton.roundCorners()
        
         firstName.clearButtonMode = .whileEditing
        
        errorText.text = ""
        
        setDismissButton()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func continueButtonPressed(_ sender: Any) {
        
        let isFirstNameEmpty = firstName.text?.isEmpty ?? true
        if isFirstNameEmpty{
            print("First anem can't be leeft blank")
            errorText.text = "Name can't be left blank"
            ProgressHUD.showError("Error")
        }else{
            print("success with first and last name")
            errorText.text = ""
            User.shared.name = firstName.text
            self.performSegue(withIdentifier: "goToBirthday", sender: self)
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
