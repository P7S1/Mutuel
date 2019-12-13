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
let db = Firestore.firestore()

var userListener: ListenerRegistration?
var appDidLoad = false
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("did finish launching")
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        NotificationCenter.default.addObserver(self, selector: #selector(logUserIn), name:NSNotification.Name(rawValue: "logUserIn"), object: nil)
        
        self.window?.tintColor = .systemPink
        SvrfSDK.authenticate(onSuccess: {
          print("Successfully authenticated with the Svrf API!")
        }, onFailure: { err in
          print("Could not authenticate with the Svrf API: \(err)")
        })
        FirebaseApp.configure()
        if #available(iOS 13.0, *) {
            configureNavBariOS13()
        } else {
           configureNavBar()
            // Fallback on earlier versions
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
        if #available(iOS 13.0, *) {
            ProgressHUD.statusColor(.label)
        }
        
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
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
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func configureNavBar(){
        let navigationBarAppearace = UINavigationBar.appearance()
        navigationBarAppearace.tintColor = .systemPink
            navigationBarAppearace.barTintColor = UIColor.white
        navigationBarAppearace.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.black]

        
        navigationBarAppearace.prefersLargeTitles = true
    
        navigationBarAppearace.backgroundColor = .clear
    }
    
    @available(iOS 13.0, *)
    func configureNavBariOS13(){
      let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithDefaultBackground()
        navBarAppearance.backgroundColor = .none
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        //navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        UINavigationBar.appearance().tintColor = .systemPink
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        
        let largeTitleAppearence = UINavigationBarAppearance()
        largeTitleAppearence.configureWithOpaqueBackground()
        largeTitleAppearence.backgroundColor = .systemBackground
        largeTitleAppearence.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        UINavigationBar.appearance().scrollEdgeAppearance = largeTitleAppearence
    
    }
    
    @objc func logUserIn(){
        if let id = Auth.auth().currentUser?.uid{
        let ref = db.collection("users").document(id)
            
            ref.addSnapshotListener { (snapshot, error) in
            if error == nil{
                User.shared.convertFromDocument(dictionary: snapshot!)
                if !appDidLoad{
                    // this line is important
                    //elf.window = UIWindow(frame: UIScreen.main.bounds)
                    // In project directory storyboard looks like Main.storyboard,
                    // you should use only part before ".storyboard" as it's name,
                    // so in this example name is "Main".
                    // controller identifier sets up in storyboard utilities
                    // panel (on the right), it called Storyboard ID
                    
                /*    let viewController = storyboard.instantiateViewController(withIdentifier: "TabBarController") as! TabBarController
                    UIView.animate(withDuration: 0.2) {
                        self.window?.rootViewController = viewController
                        self.window?.makeKeyAndVisible()
                    } */
                    
                    let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "TabBarController") as! TabBarController

                    UIApplication.shared.windows.first?.rootViewController = vc
                    appDidLoad = true
                }
                if let tokens = snapshot?.get("fcmToken") as? [String]
                                ,let token = Messaging.messaging().fcmToken {
                    if !tokens.contains(token){
                        let pushManager = PushNotificationManager(userID: id)
                        pushManager.registerForPushNotifications()
                    }
                }
            }else{
                print("error logging user in \(error!)")
            }
            }
            
        }
        
}
    
    

}
