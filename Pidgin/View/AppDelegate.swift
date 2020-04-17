//
//  AppDelegate.swift
//  PhotoVideoEditor
//
//  Created by Faris Albalawi on 11/12/18.
//  Copyright © 2018 Faris Albalawi. All rights reserved.
//

import UIKit
import SvrfSDK 
import Firebase
import FirebaseFirestore
import GiphyUISDK
import FirebaseDatabase
import NotificationBannerSwift
import AVFoundation
import DZNEmptyDataSet
import GoogleMobileAds
let db = Firestore.firestore()

var ref: DatabaseReference!

var userListener: ListenerRegistration?
var appDidLoad = false
var firstLaunch = false
@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        NotificationCenter.default.addObserver(self, selector: #selector(logUserIn), name:NSNotification.Name(rawValue: "logUserIn"), object: nil)
        
        self.window?.tintColor = .label
        SvrfSDK.authenticate(onSuccess: {
          print("Successfully authenticated with the Svrf API!")
        }, onFailure: { err in
          print("Could not authenticate with the Svrf API: \(err)")
        })
        FirebaseApp.configure()
        GADMobileAds.sharedInstance().start(completionHandler: nil)
       /* GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers =
        [ "cd909356c46c0ab3c0152ac8f5ecb896" ] */
        ref = Database.database().reference()
        Giphy.configure(apiKey: "jqEwvwCYxQjIehwIZpHnLKns5NMG0rd8", verificationMode: false)
        GiphyViewController.trayHeightMultiplier = 1
        if #available(iOS 13.0, *) {
            configureNavBariOS13()
        }
        
        if Auth.auth().currentUser != nil {
            print("user is signed in")
            logUserIn()
        } else {
            appDidLoad = true
            print("user is not signed in")
            // this line is important
           // self.window = UIWindow(frame: UIScreen.main.bounds)
            // In project directory storyboard looks like Main.storyboard,
            // you should use only part before ".storyboard" as it's name,
            // so in this example name is "Main".
            let storyboard = UIStoryboard.init(name: "Login", bundle: nil)

            let vc = storyboard.instantiateViewController(withIdentifier: "WelcomeViewController") as! WelcomeViewController
            
            UIApplication.shared.windows.first?.rootViewController = vc
            appDidLoad = true
        }

            ProgressHUD.statusColor(.label)
        
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.videoRecording, options: .mixWithOthers)
             try AVAudioSession.sharedInstance().setActive(true)
        } catch {
             print(error)
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        if let uid = User.shared.uid{
        let docRef = ref.child("/badgeCount/\(uid)")
        application.applicationIconBadgeNumber = 0
        docRef.removeValue()
        }
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.

    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    @available(iOS 13.0, *)
    func configureNavBariOS13(){
      let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.backgroundColor = .systemBackground
        navBarAppearance.shadowColor = .none
      /*  self.navigationController?.navigationBar.layer.shadowColor = UIColor.lightGray.cgColor
        self.navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        self.navigationController?.navigationBar.layer.shadowRadius = 4.0
        self.navigationController?.navigationBar.layer.shadowOpacity = 1.0
        self.navigationController?.navigationBar.layer.masksToBounds = false
        navBarAppearanc */
        navBarAppearance.largeTitleTextAttributes = [NSAttributedString.Key.font : UIFont(name: "AvenirNext-Bold", size: 30
        )!]
        navBarAppearance.titleTextAttributes = [NSAttributedString.Key.font : UIFont(name: "AvenirNext-Bold", size: 17
        )!]
        navBarAppearance.backgroundEffect = .none
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = .label
        UITabBar.appearance().tintColor = .systemPink
        UITabBar.appearance().backgroundColor = .systemBackground

    }
    
    @objc func logUserIn(){
        if let id = Auth.auth().currentUser?.uid{
        let ref = db.collection("users").document(id)
            
            userListener = ref.addSnapshotListener { (snapshot, error) in
            if error == nil{
                self.checkIfFirstTimeLaunching()
                User.shared.convertFromDocument(dictionary: snapshot!)
                if User.shared.username != nil{
                if !appDidLoad{
    
                    let vc = TabBarController()
                    UIApplication.shared.windows.first?.rootViewController = vc
                    appDidLoad = true
                }
                 
                }else{
                    print("User has invalid username")
                    self.presentUsernameVC()
                }
            }else{
                print("error logging user in \(error!)")
            }
            }
            
        }
        
}
    
    func checkIfFirstTimeLaunching(){
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
        if launchedBefore  {
            print("Not first launch.")
            firstLaunch = false
        } else {
            print("First launch, setting UserDefault.")
            firstLaunch = true
            UserDefaults.standard.set(true, forKey: "launchedBefore")
        }
    }
    
    func presentUsernameVC(){
        let storyboard = UIStoryboard.init(name: "Login", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "UsernameViewController") as! UsernameViewController
        let navBar = UINavigationController(rootViewController: vc)
        UIApplication.shared.windows.first?.rootViewController = navBar
    }

    
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        if let aps = userInfo["aps"] as? NSDictionary {
            if let alert = aps["alert"] as? NSDictionary {
                
                if let message = alert["body"] as? String{
                    let title = alert["title"] as? String
                    let banner = NotificationBanner(title: title, subtitle: message, style: .info, colors: CustomBannerColors())
                    banner.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 17
                    )!
                    banner.subtitleLabel?.font = UIFont(name: "Avenir-Next Medium", size: 15
                    )!
                    banner.subtitleLabel?.textColor = .secondaryLabel
                    banner.titleLabel?.textColor = .label
                    
                    guard let tabbarController = self.window?.rootViewController as? TabBarController else {
                        // your rootViewController is no UITabbarController
                        return
                    }
                    guard let selectedNavigationController = tabbarController.selectedViewController as? UINavigationController else {
                        // the selected viewController in your tabbarController is no navigationController!
                        return
                    }
                    
                    if selectedNavigationController.visibleViewController is ChatViewController{
                        
                    }else{
                        banner.show()
                    }
                   
                }
                
        }
    }
        completionHandler(.newData)
    }
    
   

}

