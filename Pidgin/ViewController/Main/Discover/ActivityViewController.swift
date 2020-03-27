//
//  ActivityViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/7/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import FirebaseFirestore
import DZNEmptyDataSet
class ActivityViewController: HomeViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var originalQuery : Query!
    
    var items : [ActivityItem]  = [ActivityItem]()
    
    @IBOutlet weak var followRequestsLabel: UILabel!
    @IBOutlet weak var viewRequestsButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configureNavItem(name: "Activity")
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        
        self.originalQuery = db.collection("users").document(User.shared.uid!).collection("activity").limit(to: 16).order(by: "date", descending: true)
        
        if User.shared.isPrivate{
            followRequestsLabel.text = " \(User.shared.followRequestsCount) Follow Requests"
            viewRequestsButton.roundCorners()
        }else{
            followRequestsLabel.isHidden = true
            viewRequestsButton.isHidden = true
            tableView.contentInset = UIEdgeInsets(top: -50, left: 0, bottom: 0, right: 0)
        }
        
        
        
        
        originalQuery.getDocuments { (snapshot, error) in
            if error == nil{
                for document in snapshot!.documents{
                    let item = ActivityItem(document: document)
                    self.items.append(item)
                }
                self.tableView.reloadData()
            }else{
                print("there was an error \(error!)")
            }
        }
        // Do any additional setup after loading the view.
    }
    
    @IBAction func viewRequetsTapped(_ sender: Any) {
        print("Followers label tapped")
               let vc = storyboard?.instantiateViewController(identifier: "FollowRequestTableViewController") as! FollowRequestTableViewController
               navigationController?.pushViewController(vc, animated: true)
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

extension ActivityViewController : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        
        item.pushVC { (vc) in
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityTableViewCell") as! ActivityTableViewCell
        
        let activityItem = items[indexPath.row]
        cell.subtitle.text = activityItem.subtitle
        cell.date.text = activityItem.date.getElapsedInterval()
        
        cell.icon.image = activityItem.getImage()
        cell.icon.tintColor = activityItem.getColor()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    
}

extension ActivityViewController : DZNEmptyDataSetSource, DZNEmptyDataSetDelegate{
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
         return UIImage.init(systemName: "bolt", withConfiguration: EmptyStateAttributes.shared.config)?.withTintColor(.label)
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "No Acitivty", attributes: EmptyStateAttributes.shared.title)
    }
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Your followers, reposts, and comments will appear here", attributes: EmptyStateAttributes.shared.subtitle)
    }
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        return self.items.isEmpty
    }

    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
    func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
    
}
