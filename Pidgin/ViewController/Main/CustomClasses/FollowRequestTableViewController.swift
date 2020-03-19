//
//  FollowRequestTableViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/19/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import FirebaseFirestore
class FollowRequestTableViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var items : [Relationship] = [Relationship]()
    
    var lastDocument : DocumentSnapshot?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        
        navigationItem.title = "Follow Requests"
        
        tableView.delegate = self
        tableView.dataSource = self
        
        getFollowRequests()

    }



func getFollowRequests(){
    let docRef = db.collectionGroup("relationships").whereField("followed", isEqualTo: User.shared.uid ?? "undefined").whereField("isApproved", isEqualTo: false).order(by: "creationDate", descending: true)
    
    docRef.getDocuments { (snapshot, error) in
        if error == nil{
            for document in snapshot!.documents{
                let item = Relationship(document: document)
                self.lastDocument = document
                self.items.append(item)
            }
            self.tableView.reloadData()
            
        }else{
            print("there was an error \(error!.localizedDescription))")
        }
    }
}
}

extension FollowRequestTableViewController: UITableViewDelegate, UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FollowRequestTableViewCell") as! FollowRequestTableViewCell
        let item = items[indexPath.row]
        
        cell.profilePictureView.kf.setImage(with: URL(string:item.followerProfileURL))
        cell.nameLabel.text = item.followerUsername
        
        cell.acceptAction = { () in
            self.items.remove(at: indexPath.row)
            tableView.reloadData()
            let docRef = db.collection("users").document(item.follower).collection("relationships").document("\(item.follower)_\(item.followed)")
            docRef.setData(["isApproved" : true], merge: true)
        }
        cell.declineAction = { () in
            self.items.remove(at: indexPath.row)
            tableView.reloadData()
            let docRef = db.collection("users").document(item.follower).collection("relationships").document("\(item.follower)_\(item.followed)")
            docRef.delete()
        }
        
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        let docRef = db.collection("users").document(items[indexPath.row].follower)
        
        docRef.getDocument { (snapshot, error) in
            tableView.deselectRow(at: indexPath, animated: true)
            let user = Account()
            user.convertFromDocument(dictionary: snapshot!)
            let vc = self.storyboard?.instantiateViewController(identifier: "ExploreViewController") as! ExploreViewController
            vc.user = user
            vc.isUserProfile = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    
}
