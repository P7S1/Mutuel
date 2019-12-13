//
//  NotificationService.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 12/5/19.
//  Copyright © 2019 Atemnkeng Fontem. All rights reserved.
//

import Foundation
class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        let userInfo: [AnyHashable : Any] = (bestAttemptContent?.userInfo)!
        if let _ = userInfo["aps"] as? [AnyHashable: Any], let bestAttemptContent = bestAttemptContent  {
            //add thread-id to group notification.
            let patientId = userInfo["thread-id"] as! String
            bestAttemptContent.threadIdentifier = patientId
            contentHandler(bestAttemptContent)
        }
    }
}
