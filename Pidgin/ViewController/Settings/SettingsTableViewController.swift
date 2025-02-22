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
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
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
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = self.view.frame
        alert.addAction(UIAlertAction(title: "Log Out", style: .default, handler: { (action) in
            self.returnToLoginScreen()
            
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            print("user cancelled sign out")
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0:
           return self.getHeaderView(with: "My Account", tableView: tableView)
        case 1:
            return self.getHeaderView(with: "General", tableView: tableView)
        case 2:
            return self.getHeaderView(with: "Support", tableView: tableView)
        case 3:
            return self.getHeaderView(with: "Legal", tableView: tableView)
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 45
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                let vc = EditProfileViewController()
                navigationController?.pushViewController(vc, animated: true)
            case 1:
                showShareAppDialog()
            case 2:
                let vc = storyboard?.instantiateViewController(identifier: "BlockedUsersViewController") as! BlockedUsersViewController
                navigationController?.pushViewController(vc, animated: true)
            default:
                return
            }
        case 1:
            switch indexPath.row {
                
            case 0:
                launchWebView(title: "About", link: "https://www.mutuel.live/")
            case 1:
                requestReviewManually()
            case 2:
                launchIGISafari()
            default:
                return
            }
        case 2:
            switch indexPath.row {
            case 0:
                launchIGISafari()
            case 1:
                launchIGISafari()
            case 2:
                guard let url = URL(string: "https://testflight.apple.com/join/e39lzipr") else { return }
                UIApplication.shared.openURL(url)
            default:
                return
            }
        case 3:
            switch indexPath.row {
            case 0:
                launchWebView(title: "Privacy Policy", link: "https://www.mutuel.live/privacy-policy-1")
            case 1:
                launchWebView(title: "Terms of Service", link: "https://www.mutuel.live/terms-of-service")
            default:
                return
            }
        default:
            return
        }
    }
    
    func launchWebView(title : String, link : String){
        print("launch webview")
        let vc = WebViewController()
        vc.navTitle = title
        vc.url = URL(string: link)
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
    
    func launchIGISafari(){
        guard let url = URL(string: "https://www.instagram.com/officialmutuel/") else { return }
        UIApplication.shared.openURL(url)
    }
    
    func requestReviewManually() {
        // Note: Replace the XXXXXXXXXX below with the App Store ID for your app
        //       You can find the App Store ID in your app's product URL
        guard let writeReviewURL = URL(string: "https://itunes.apple.com/app/id1498709902?action=write-review")
            else { fatalError("Expected a valid URL") }
        UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
    }

}
