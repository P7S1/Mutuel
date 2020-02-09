//
//  ReAuthenticationViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 1/20/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import Eureka
import FirebaseAuth

class ReAuthenticationViewController: FormViewController{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        NotificationCenter.default.addObserver(self, selector: #selector(presentNotification), name: NSNotification.Name(rawValue: "presentNotification"), object: nil)
        navigationItem.title = "Password"
        continueButton()
        form +++ Section("Please re-enter your password")
            <<< PasswordRow("password"){
                row in
            row.title = "Password"
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
    
    @objc func continueButtonPressed(){
        let formvalues = self.form.values()
        let user = Auth.auth().currentUser
        
        guard let password = formvalues["password"] as? String else { return }
        guard let email = user?.email else { return }
        
        ProgressHUD.show()
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)

        // Prompt the user to re-provide their sign-in credentials

        user?.reauthenticate(with: credential, completion: { (result, error) in
            if error == nil{
                ProgressHUD.dismiss()
                let vc = ChangePasswordViewController()
                self.navigationController?.pushViewController(viewController: vc, animated: true, completion: {
                    var navArray:Array = (self.navigationController?.viewControllers)!
                    navArray.remove(at: navArray.count-2)
                    self.navigationController?.viewControllers = navArray
                })
            }else{
                ProgressHUD.showError("Incorrect Password")
                print("there was an error")
            }
        })
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
   
    func continueButton(){
        let settings = UIButton.init(type: .custom)
        settings.setTitle("Continue", for: .normal)
        settings.setTitleColor(.systemPink, for: .normal)
        settings.addTarget(self, action:#selector(continueButtonPressed), for:.touchUpInside)
        let settingsButton = UIBarButtonItem.init(customView: settings)
        navigationItem.rightBarButtonItems = [settingsButton]
    }
    
    
    
    
}
