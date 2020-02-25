//
//  EditProfileViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 11/20/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import Eureka
import ViewRow
import FirebaseFirestore
import CropViewController
class EditProfileViewController: FormViewController {
    
    var profileImage : UIImage?
    
    var cellView : ProfilePicture!

    override func viewDidLoad() {
            super.viewDidLoad()
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        NotificationCenter.default.addObserver(self, selector: #selector(presentNotification), name: NSNotification.Name(rawValue: "presentNotification"), object: nil)
        saveChangesButton()
            navigationItem.title = "Account Settings"
            form +++ Section("")
                <<< ViewRow<ProfilePicture>("view") { (row) in
                    row.title = nil // optional
                }
                .cellSetup { (cell, row) in
                    //  Construct the view
                    self.cellView = ProfilePicture(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 156))
                    cell.view = self.cellView
                    cell.view?.backgroundColor = cell.backgroundColor
                    
                    let tap = UITapGestureRecognizer(target: self, action: #selector(self.profilePictureTapped))
                    cell.view?.addGestureRecognizer(tap)
                }
            form +++ Section("")
                <<< NameRow(){ row in
                    row.title = "Display Name"
                    row.tag = "displayName"
                    row.placeholder = "Enter your name here"
                    row.value = User.shared.name
                }.cellSetup({ (cell, row) in
                    cell.textField.keyboardType = .default
                })
                <<< AccountRow(){ row in
                    row.title = "Username"
                    row.tag = "username"
                    row.value = User.shared.username
                    row.evaluateDisabled()
                }.cellSetup({ (cell, row) in
                cell.textField.isEnabled = false
                cell.textField.isUserInteractionEnabled = false
                }).cellUpdate({ (cell, row) in
                    cell.textField.textColor = .secondaryLabel
                })
         form +++ Section("")
                <<< EmailRow(){ row in
                    row.title = "Email"
                    row.tag = "email"
                    row.placeholder = "Enter Email Here"
                    row.value = User.shared.email
                    }.cellSetup({ (cell, row) in
                    cell.textField.isEnabled = false
                    cell.textField.isUserInteractionEnabled = false
                    }).cellUpdate({ (cell, row) in
                        cell.textField.textColor = .secondaryLabel
                    })
                <<< DateRow(){ (row) in
                        row.tag = "dob"
                        row.title = "Date of Birth"
                        row.value = User.shared.birthday ?? Date()
                }.cellSetup({ (cell, row) in
                    cell.detailTextLabel?.textColor = .label
                })
                <<< ButtonRow(){
                    $0.title = "Change Password"
                    $0.onCellSelection { (cell, row) in
                       let vc = ReAuthenticationViewController()
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }.cellSetup({ (cell, row) in
                    cell.tintColor = .systemPink
                    
                })
             form +++ Section("")
                <<< SwitchRow("privateAccount"){
                        $0.title = "Private Account"
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
    
    @objc func profilePictureTapped(){
       print("did recognize tap")
        let alertController = UIAlertController(title: nil, message: nil , preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { (action) in
            print("chose take photo")
            
        }))
           
           alertController.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action) in
               print("chose choose from camera roll")
               
               let myPickerController = UIImagePickerController()
               myPickerController.delegate = self
               myPickerController.sourceType = UIImagePickerController.SourceType.photoLibrary
               self.present(myPickerController, animated: true, completion: nil)
               
           }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
           self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func handleSaveButton(){
        print("save bar button pressed")
        let formvalues = self.form.values()
        
        if let image = profileImage{
            if let url = User.shared.profileURL{
            FollowersHelper.deleteImage(at: url)
            }
            let _ = FollowersHelper().uploadPicture(data1: image.jpegData(compressionQuality: 0.1), imageName: UUID().uuidString)
        }
        
        let user = User.shared
        
        if let name = formvalues["displayName"] as? String{
            user.name = name
        }
        
        if let dob = formvalues["dob"] as? Date{
            user.birthday = dob
        }
        
        let docRef = db.collection("users").document(User.shared.uid ?? "")
        
        docRef.updateData(user.representation, completion: nil)
        
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
extension EditProfileViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
   func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            if let newImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
                self.presentCropViewController(image: newImage)
            }
        }
    }
}

extension EditProfileViewController : CropViewControllerDelegate{
    func presentCropViewController(image : UIImage) {
        let cropViewController = CropViewController(croppingStyle: .circular, image: image)
      cropViewController.delegate = self
        self.present(cropViewController, animated: true, completion: nil)
    }

    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
            // 'image' is the newly cropped version of the original image
        self.profileImage = image
        cellView.imageView.image = image
        }
}
