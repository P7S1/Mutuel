//
//  ResultsTableViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 10/27/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import FirebaseFirestore
import DeepDiff
class ResultsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var tableView: UITableView!
    
    
    var results : [Account] = [Account]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        NotificationCenter.default.addObserver(self, selector: #selector(presentNotification), name: NSNotification.Name(rawValue: "presentNotification"), object: nil)
        results.removeAll()
        
        tableView.contentInset = UIEdgeInsets(top: 40, left: 00, bottom: 0, right: 00)
        tableView.delegate = self
        tableView.dataSource = self
        
    }
    
    @objc func tap(){
        print("tap")
    }
    
    override func viewDidAppear(_ animated : Bool){
        super.viewDidAppear(animated)
        results.removeAll()
        print("results view did appear")
    }

    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ExploreViewController") as! ExploreViewController
        
        vc.user = results[indexPath.row]
        vc.isUserProfile = true
        vc.isPresented = true
        vc.setDismissButton()
        
        self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return results.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return getHeaderView(with: "Users", tableView: tableView)
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchUserTableViewCell", for: indexPath) as! SearchUserTableViewCell
        
        cell.displayName.text = results[indexPath.row].name ?? ""
        cell.username.text = "@\(results[indexPath.row].username ?? "")"
        if let url = results[indexPath.row].profileURL{
            cell.profilePic.kf.setImage(with: URL(string: url), placeholder: FollowersHelper().getUserProfilePicture())
            cell.profilePic.layer.cornerRadius = cell.profilePic.bounds.height/2
            cell.profilePic.clipsToBounds = true
        }else{
            cell.profilePic.image = FollowersHelper().getUserProfilePicture()        }
        

        // Configure the cell...

        return cell
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    


}


extension ResultsTableViewController: UISearchResultsUpdating{
    func updateSearchResults(for searchController: UISearchController) {
        let result = searchController.searchBar.text ?? ""
        if !result.isEmpty{
            let docRef = db.collection("users")
            let query = docRef.order(by: "username").start(at: [result]).end(at: ["\(result)\u{f8ff}"]).limit(to: 5)
        query.getDocuments { (snapshot, error) in
            if error == nil{
                    let old = self.results
                    var newItems = [Account]()
                    for document in snapshot!.documents{
                        let user = Account()
                        user.convertFromDocument(dictionary: document)
                        newItems.append(user)
                    }
                self.tableView.performBatchUpdates({
                    let changes = diff(old: old, new: newItems)
                    self.tableView.reload(changes: changes, section: 0, updateData: {
                        self.results = newItems
                    })
                }, completion: nil)
                    
                
            }else{
                print("error getting data: \(error!)")
            }
        }
        }else{
            tableView.performBatchUpdates({
                let old = self.results
                let newItems = [Account]()
                let changes = diff(old: old, new: newItems)
                self.tableView.reload(changes: changes, section: 0, updateData: {
                    self.results = newItems
                })
            }, completion: nil)
            
        }
    }
    
}

extension ResultsTableViewController: UISearchControllerDelegate, UISearchBarDelegate{
    
}
