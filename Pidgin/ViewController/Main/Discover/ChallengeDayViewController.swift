//
//  ChallengeDayViewController.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 3/17/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import UIKit
import FirebaseMessaging
import FirebaseFirestore
class ChallengeDayViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var challenge : Challenge!
    
    var days : [ChallengeDay] = [ChallengeDay]()
    
    var notificationButton : UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backButton = UIBarButtonItem()
        backButton.title = " " //in your case it will be empty or you can put the title of your choice
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
    
        
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationItem.title = challenge.title
        
         notificationButton = UIBarButtonItem(image: UIImage(systemName: "bell"), style: .plain, target: self, action: #selector(notificationPressed))
        
        navigationItem.rightBarButtonItem = notificationButton
        
        updateNotificationItem(toggle: false)
        
        self.days = challenge.days

        // Do any additional setup after loading the view.
    }
    
    @objc func notificationPressed(){
        updateNotificationItem(toggle: true)
        
        
    }
    
    func updateNotificationItem(toggle : Bool){
       var notificationsEnabled = UserDefaults.standard.value(forKey: challenge.id) as? Bool ?? false
        
        if !toggle{
            notificationsEnabled.toggle()
        }
        
        if notificationsEnabled{
            if toggle{
          
                ProgressHUD.show()
                
                Messaging.messaging().unsubscribe(fromTopic: challenge.id) { (error) in
                    if error == nil{
                        ProgressHUD.showSuccess("Reminders Disabled")
                        UserDefaults.standard.set(false, forKey: self.challenge.id)
                    }else{
                        print(error!.localizedDescription)
                    }
                }
                
            }
            notificationButton.image = UIImage(systemName: "bell")
            notificationButton.tintColor = .label
        }else{
            if toggle{
          ProgressHUD.show()
                Messaging.messaging().subscribe(toTopic: challenge.id) { (error) in
                    if error == nil{
                        ProgressHUD.showSuccess("Reminders Enabled")
                        UserDefaults.standard.set(true, forKey: self.challenge.id)
                        }else{
                            print(error!.localizedDescription)
                        }
                }
            }
            notificationButton.image = UIImage(systemName: "bell")
            notificationButton.tintColor = .systemGreen
        }
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

extension ChallengeDayViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return days.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChallengeDayTableViewCell") as! ChallengeDayTableViewCell
        
        let day = days[indexPath.row]
        
        cell.activityLabel.text = day.activity
        cell.dateLabel.text = "Day \(day.day)"
        
        cell.makeAPostAction = {
            () in
        let vc = UploadViewController()
            vc.challengeDay = day
            vc.challenge = self.challenge
            vc.isChallenge = true
            self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        }
    
        let dayInterval = abs(challenge.startDate.interval(ofComponent: .day, fromDate: Date()))
        
        let isEnabled = dayInterval >= day.day
        print("Interver \(dayInterval)")
        print("Day \(day.day)")
        print("Is enabled: \(isEnabled)")
        if isEnabled{
            cell.makeAPostButton.setTitleColor(.systemPink, for: .normal)
            cell.makeAPostButton.alpha = 1.0
        }else{
            cell.makeAPostButton.setTitleColor(.secondaryLabel, for: .normal)
            cell.makeAPostButton.alpha = 0.5
        }
        cell.makeAPostButton.isEnabled = isEnabled
        
        
        cell.makeAPostButton.roundCorners()
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let day = days[indexPath.row]
        
        let dayInterval = abs(challenge.startDate.interval(ofComponent: .day, fromDate: Date()))
        
        let isEnabled = dayInterval >= day.day
        
        tableView.deselectRow(at: indexPath, animated: true)
        if isEnabled{
        let storyboard = UIStoryboard(name: "Discover", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "ExploreViewController") as! ExploreViewController
        vc.isUserProfile = false
        vc.query = db.collectionGroup("posts").whereField("isRepost", isEqualTo: false).whereField("challengeDayID", isEqualTo: day.id)
        vc.navigationItem.title = day.activity
        navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
}
