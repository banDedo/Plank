//
//  NotificationListener.swift
//  Plank
//
//  Created by Patrick Hogan on 9/9/14.
//  Copyright (c) 2014 bandedo. All rights reserved.
//

import UIKit

let failedUserInfoElement = "Tag"

class NotificationListener: NSObject {
    var notifications: [NSNotification]
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    init(name: String, object: AnyObject?) {
        notifications = Array()
        
        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleNotification:", name: name, object: object)
    }
    
    func handleNotification(notification: NSNotification) {
        notifications.append(notification)
    }
    
    func userInfoElement(index: Int, key: NSObject) -> AnyObject? {
        if self.notifications.count <= index {
            return failedUserInfoElement
        }
        
        var userInfo = self.notifications[index].userInfo
        if userInfo == nil {
            return failedUserInfoElement
        }
        
        return userInfo![key]
    }
}

