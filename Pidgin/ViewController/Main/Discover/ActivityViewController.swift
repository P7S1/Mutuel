//
//  ActivityViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/7/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import FirebaseFirestore
class ActivityViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var originalQuery : Query!
    
    var items : [ActivityItem]  = [ActivityItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
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
        cell.title.text = activityItem.title
        cell.subtitle.text = activityItem.subtitle
        cell.date.text = activityItem.date.getElapsedInterval()
        
        cell.icon.image = activityItem.getImage()
        cell.icon.tintColor = activityItem.getColor()
        
        return cell
    }
    
    
}
