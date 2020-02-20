import Firebase
import FirebaseFirestore
import FirebaseMessaging
import UIKit
import UserNotifications
import FirebaseDatabase
class PushNotificationManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
    let userID: String
    init(userID: String) {
        self.userID = userID
        super.init()
    }
    func registerForPushNotifications() {
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            // For iOS 10 data message (sent via FCM)
            Messaging.messaging().delegate = self
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
        UIApplication.shared.registerForRemoteNotifications()
        updateFirestorePushTokenIfNeeded()
    }
    func updateFirestorePushTokenIfNeeded() {
        if let token = Messaging.messaging().fcmToken,
            let userID = User.shared.uid,
            let deviceID = UIDevice.current.identifierForVendor?.uuidString{
            ref.child("devices/\(userID)/\(deviceID)").setValue(token) { (error, ref) in
                if error == nil{
                    print("successfully registered for push notificaitons")
                }else{
                    print("there was an error \(error!.localizedDescription)")
                }
            }
        }
    }
    
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print(remoteMessage.appData)
        print("did receive")
    }
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("did receive registration token")
       // updateFirestorePushTokenIfNeeded()
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print(response)
    }
}


class PushNotificationSender {
    func sendPushNotification(to token: String, title: String, body: String, tag: String?, badge : String?) {
        let urlString = "https://fcm.googleapis.com/fcm/send"
        let url = NSURL(string: urlString)!
        let paramString: [String : Any] = ["to" : token,
                                           "notification" : ["title" : title, "body" : body,"sound": "default", "badge" : nil],
                                           "data" : ["user" : User.shared.uid]
        ]
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=AAAAwOW63U8:APA91bHXPe9dQIIPliQlIOLC8QFAre6K6CbeUt-US3W9nrKASbNYb_9XBb6Hcn-1WlaqRpwO2duF2jlSSCzW-kTyQkzlwXj6E64rFB-7TGPP-H3J7tjjFxI5hwDgAzf2hAj4xk0nuEu_", forHTTPHeaderField: "Authorization")
        let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
            do {
                if let jsonData = data {
                    if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                        NSLog("Received data:\n\(jsonDataDict))")
                    }
                }
            } catch let err as NSError {
                print(err.debugDescription)
            }
        }
        task.resume()
    }
}
