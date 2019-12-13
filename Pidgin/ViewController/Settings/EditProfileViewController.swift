//
//  EditProfileViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 11/20/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import Eureka
import ImageRow
import FirebaseFirestore
class EditProfileViewController: FormViewController {

    override func viewDidLoad() {
            super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(presentNotification), name: NSNotification.Name(rawValue: "presentNotification"), object: nil)
        saveChangesButton()
            navigationItem.title = "Account Settings"
        self.view.tintColor = .systemPink
            form +++ Section("")
                <<< ImageRow() {
                    $0.title = "Profile picture"
                    $0.sourceTypes = .PhotoLibrary
                    $0.clearAction = .yes(style: .destructive)
                    $0.tag = "profilePicURL"
                }
                .cellUpdate { cell, row in
                    cell.accessoryView?.layer.cornerRadius = 17
                    cell.accessoryView?.frame.size = CGSize(width: 34, height: 34)
                }
            form +++ Section("")
                <<< NameRow(){ row in
                    row.title = "Display Name"
                    row.placeholder = "Enter your name here"
                    row.value = User.shared.name

                }
                <<< AccountRow(){ row in
                    row.title = "Username"
                    row.placeholder = "Enter Username Here"
                    row.value = User.shared.username
                }
                <<< TextRow(){ row in
                    row.title = "Bio"
                    row.placeholder = "Say something about yourself"
                }
                form +++ Section("")
                <<< EmailRow(){ row in
                    row.title = "Email"
                    row.placeholder = "Enter Email Here"
                    row.value = User.shared.email
                }
                <<< PhoneRow(){
                    $0.title = "Phone"
                    $0.placeholder = "Enter phone number here"
                }
                <<< DateRow(){
                    $0.title = "Date of Birth"
                    $0.value = Date(timeIntervalSinceReferenceDate: 0)
                }
                <<< ButtonRow(){
                    $0.title = "Change Password"
                }
             form +++ Section("")
                <<< SwitchRow("privateAccount"){
                        $0.title = "Private Account"
                }.cellSetup({ (cell, row) in
                    cell.switchControl.onTintColor = UIColor.systemPink
                })
                <<< ButtonRow(){
                    $0.title = "Blocked List"
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
        print("save bar button pressed")
        let formvalues = self.form.values()
        
        let image = formvalues["profilePicURL"] as? UIImage
       FollowersHelper().uploadPicture(data1: image?.jpegData(compressionQuality: 0.1), imageName: UUID().uuidString)
        
        
        navigationController?.popToRootViewController(animated: true)
        
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
