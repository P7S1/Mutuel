//
//  ResultsTableViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 10/27/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import FirebaseFirestore
class ResultsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var tableView: UITableView!
    
    
    var results : [Account] = [Account]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(presentNotification), name: NSNotification.Name(rawValue: "presentNotification"), object: nil)
        results.removeAll()
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
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        
        vc.user = results[indexPath.row]
               
        let VC = UINavigationController(rootViewController: vc)
        self.present(VC, animated: true, completion: nil)
        
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
        results.removeAll()
        self.tableView.reloadData()
        if let result = searchController.searchBar.text{
            let docRef = db.collection("users")
            let query = docRef.whereField("username", isGreaterThan: result.lowercased()).limit(to: 3)
        
        query.getDocuments { (snapshot, error) in
            if error == nil{
                if snapshot?.count == 0{
                    print("no results for \(result)")
                    self.tableView.reloadData()
                }else{
                    for document in snapshot!.documents{
                        let user = Account()
                        user.convertFromDocument(dictionary: document)
                        self.results.append(user)
                        self.tableView.reloadData()
                    }
                }
            }else{
                print("error getting data: \(error!)")
            }
        }
        }
    }
    
}

extension ResultsTableViewController: UISearchControllerDelegate, UISearchBarDelegate{
    
}
