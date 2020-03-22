//
//  BlockedUsersViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/22/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import FirebaseFirestore
class BlockedUsersViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var users : [BlockedUser] = [BlockedUser]()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        self.navigationItem.title = "Blocked Users"
        
        tableView.delegate = self
        tableView.dataSource = self
        
        let docRef = db.collection("users").document(User.shared.uid!).collection("blocked").limit(to: 25).order(by: "creationDate", descending: true)
        
        docRef.getDocuments { (snapshot, error) in
            if error == nil{
                for document in snapshot!.documents{
                    let user = BlockedUser(document: document)
                    self.users.append(user)
                }
                self.tableView.reloadData()
            }else{
                print("there was an error : \(error!.localizedDescription)")
            }
        }
        // Do any additional setup after loading the view.
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

extension BlockedUsersViewController : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let docRef = db.collection("users").document(users[indexPath.row].id)
        
        docRef.getDocument { (document, error) in
            if error == nil{
                let user = Account()
                user.convertFromDocument(dictionary: document!)
                let storyboard = UIStoryboard.init(name: "Discover", bundle: nil)
                let vc = storyboard.instantiateViewController(identifier: "ExploreViewController") as! ExploreViewController
                vc.isUserProfile = true
                vc.user = user
                tableView.deselectRow(at: indexPath, animated: true)
                self.navigationController?.pushViewController(vc, animated: true)
            }else{
                print("threre was ane rror \(error!.localizedDescription)")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlockedUserTableViewCell") as! BlockedUserTableViewCell
        let user = users[indexPath.row]
        cell.username.text = user.username
        cell.unblockAction = { () in
            self.users.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            user.unblockUser { (completion) in
                print("user unblocked")
            }
        }
        return cell
    }
    
    
}
