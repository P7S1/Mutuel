//
//  SettingsTableViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 10/24/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import FirebaseAuth
class SettingsTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(presentNotification), name: NSNotification.Name(rawValue: "presentNotification"), object: nil)
        self.navigationItem.title = "Settings"
        navigationItem.largeTitleDisplayMode = .never
        tableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkIfSignedIn()
    }
    
    @IBAction func logOutButtonPressed(_ sender: Any) {
        print("log out button pressed")
        
        let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Log Out", style: .default, handler: { (action) in
            self.returnToLoginScreen()
            
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            print("user cancelled sign out")
        }))
        alert.view.tintColor = .systemPink
        self.present(alert, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                let vc = EditProfileViewController()
                navigationController?.pushViewController(vc, animated: true)
            default:
                return
            }
        case 1:
            switch indexPath.row {

            case 2:
                requestReviewManually()
            default:
                return
            }
        case 2:
            switch indexPath.row {
            case 0:
                launchWebView(title: "Report bug/feedback")
            case 1:
                launchWebView(title: "Contact")
            case 2:
                launchWebView(title: "Beta testers")
            default:
                return
            }
        case 3:
            switch indexPath.row {
            case 0:
                launchWebView(title: "Privacy Policy")
            case 1:
                launchWebView(title: "Terms and Conditions")
            default:
                return
            }
        default:
            return
        }
    }
    
    func launchWebView(title : String){
        print("launch webview")
        let vc = WebViewController()
        vc.title = title
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func checkIfSignedIn(){
      if Auth.auth().currentUser != nil {
            print("user is signed in")
        } else {
            print("user is not signed in")
            returnToLoginScreen()
        }
    }
    
    func requestReviewManually() {
        // Note: Replace the XXXXXXXXXX below with the App Store ID for your app
        //       You can find the App Store ID in your app's product URL
        guard let writeReviewURL = URL(string: "https://itunes.apple.com/app/id1477275391?action=write-review")
            else { fatalError("Expected a valid URL") }
        UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
    }

}
