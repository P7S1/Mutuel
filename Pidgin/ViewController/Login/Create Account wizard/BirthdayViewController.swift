//
//  BirthdayViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 10/23/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit

class BirthdayViewController: UIViewController {

    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var pickerView: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        continueButton.roundCorners()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func continueButtonPressed(_ sender: Any) {
        User.shared.birthday = pickerView.date
        self.performSegue(withIdentifier: "goToUsername", sender: self)
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
