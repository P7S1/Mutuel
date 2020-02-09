//
//  FollowersTableViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 11/12/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
class FollowersTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet weak var createGroupButton: UIButton!
    @IBOutlet weak var createGroupView: UIView!
    @IBOutlet weak var tableView: UITableView!
    var viewTitle = ""
    var type = ""
    var user : Account?
    
    var results : [Account] = [Account]()
    
    var query : Query!
    
    var lastDocument : DocumentSnapshot?
    
    var loadedAllDocs = false
    
    var queryLimit = 5

    override func viewDidLoad() {
        super.viewDidLoad()
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        NotificationCenter.default.addObserver(self, selector: #selector(presentNotification), name: NSNotification.Name(rawValue: "presentNotification"), object: nil)
        tableView.delegate = self
        tableView.dataSource = self
        navigationItem.largeTitleDisplayMode = .never
        formatForType()
        navigationItem.title = viewTitle
        createGroupButton.backgroundColor = .systemGray6
        createGroupButton.setTitleColor(.label, for: .normal)
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
    
    func formatForType(){
        switch type {
        case "followers":
            viewTitle = "Followers"
            createGroupButton.isEnabled = false
            createGroupView.removeFromSuperview()
            tableView.layoutIfNeeded()
            self.view.layoutIfNeeded()
            getUsersFollowers()
        case "following":
            viewTitle = "Following"
            createGroupButton.isEnabled = false
            createGroupView.removeFromSuperview()
            tableView.layoutIfNeeded()
            self.view.layoutIfNeeded()
            if let following = user?.following{
                query = db.collection("users").whereField(FieldPath.documentID(), in: following).limit(to: queryLimit)
                if let lastDoc = self.lastDocument{
                    self.lastDocument = lastDoc
                }
                    query.getDocuments { (snapshot, error) in
                        if error == nil{
                            if snapshot!.count < self.queryLimit{
                                self.loadedAllDocs = true
                            }
                            for document in snapshot!.documents{
                                let account = Account()
                            account.convertFromDocument(dictionary: document)
                                self.results.append(account)
                                self.lastDocument = document
                            }
                            
                            self.tableView.reloadData()
                        }else{
                            print("there was an error \(error!)")
                        }
                    }
                        
                    }
        case "newMessage":
            viewTitle = "New Message"
            user = User.shared
            createGroupButton.roundCorners()
            getUsersFollowers()
        default:
            return
        }
    }
    
    func getUsersFollowers(){
        query = db.collection("users").whereField("following", arrayContains: user?.uid ?? "").limit(to: queryLimit)
        if let doc = self.lastDocument{
            query = query.start(afterDocument: doc)
        }
        query.getDocuments { (snapshot, error) in
            if error == nil{
                if snapshot!.count < self.queryLimit{
                    self.loadedAllDocs = true
                }
                for document in snapshot!.documents{
                    let account = Account()
                    account.convertFromDocument(dictionary: document)
                    self.lastDocument = document
                    account.printClass()
                    self.results.append(account)
                }
                self.tableView.reloadData()
            }else{
                print("there was an error \(error!)")
            }
        }
    }
    @IBAction func didTapCreateGroupButton(_ sender: Any) {
        print("did tap create group")
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CreateGroupViewController") as! CreateGroupViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    

    // MARK: - Table view data source

     func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if type == "newMessage"{
        return 50
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if type == "newMessage"{
            return getHeaderView(with: "Followers", tableView: tableView)
        }else{
            return nil
        }
    }

     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return results.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == results.count && !self.loadedAllDocs{
            self.getMoreUsers()
        }
    }
    
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchUserTableViewCell", for: indexPath) as! SearchUserTableViewCell
        
        cell.displayName.text = results[indexPath.row].name ?? ""
        cell.username.text = "@\(results[indexPath.row].username ?? "")"
        
        if let url = results[indexPath.row].profileURL{
            cell.profilePic.kf.setImage(with: URL(string: url), placeholder: FollowersHelper().getUserProfilePicture())
        }else{
            cell.profilePic.image = FollowersHelper().getUserProfilePicture()        }
        cell.profilePic.layer.cornerRadius = cell.profilePic.bounds.height/2
        cell.profilePic.clipsToBounds = true
        
        // Configure the cell...

        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if type == "newMessage"{
            if let id1 = User.shared.uid, let id2 = results[indexPath.row].uid{
                let id = FollowersHelper().getChannelID(id1: id1, id2: id2)
                let docRef = db.collection("channels").document(id)
            
                let metaData = NSMutableDictionary()
                metaData.setValue(User.shared.name, forKey: id1)
                metaData.setValue(self.results[indexPath.row].name, forKey: id2)
                let profileURLs = NSMutableDictionary()
                profileURLs.setValue(User.shared.profileURL, forKey: id1)
                profileURLs.setValue(self.results[indexPath.row].profileURL, forKey: id2)
                let tokens = Array(Set(User.shared.tokens + results[indexPath.row].tokens))
                docRef.setData(["fcmToken":tokens,
                                   "members":[id1,id2],
                                   "metaData": metaData,
                               "profilePicURLs": profileURLs],
                                merge: true
                                    )
                
                docRef.getDocument { (document, error) in
                    if error == nil{
                        
                    guard var channel = Channel(document: document!) else {
                      return
                    }
                    let vc = ChatViewController()
                    vc.channel = channel
                    channel.metaData = metaData
                        self.navigationController?.pushViewController(viewController: vc, animated: true, completion: {
                            var navArray:Array = (self.navigationController?.viewControllers)!
                            navArray.remove(at: navArray.count-2)
                            self.navigationController?.viewControllers = navArray
                        })
                            
                        
                    }else{
                        print("there was an error: \(error!)")
                    }
                }
            
                } 
        }else{
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ExploreViewController") as! ExploreViewController
        vc.user = results[indexPath.row]
        vc.isUserProfile = true
        navigationController?.pushViewController(vc, animated: true)
        }
        
    }
    func getMoreUsers(){
               if let startAfter = lastDocument{
                   query = query.start(afterDocument: startAfter)
                   query.getDocuments { (snapshot, error) in
                       if error == nil{
                           if snapshot!.count < 10{
                               self.loadedAllDocs = true
                           }
                           for document in snapshot!.documents{
                           let account = Account()
                           account.convertFromDocument(dictionary: document)
                               self.results.append(account)
                           }
                        self.tableView.reloadData()
                        }
                   }
               }
           }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
           if scrollView.panGestureRecognizer.translation(in: scrollView).y < 0{
               changeTabBar(hidden: true, animated: true)
           }
           else{
               changeTabBar(hidden: false, animated: true)
           }
       }

       func changeTabBar(hidden:Bool, animated: Bool){
           guard let tabBar = self.tabBarController?.tabBar else { return; }
           if tabBar.isHidden == hidden{ return }
           let frame = tabBar.frame
           let offset = hidden ? frame.size.height : -frame.size.height
           let duration:TimeInterval = (animated ? 0.2 : 0.0)
           tabBar.isHidden = false

           UIView.animate(withDuration: duration, animations: {
               tabBar.frame = frame.offsetBy(dx: 0, dy: offset)
           }, completion: { (true) in
               tabBar.isHidden = hidden
           })
       }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension UINavigationController {

  public func pushViewController(viewController: UIViewController,
                                 animated: Bool,
                                 completion: (() -> Void)?) {
    CATransaction.begin()
    CATransaction.setCompletionBlock(completion)
    pushViewController(viewController, animated: animated)
    CATransaction.commit()
  }

}
