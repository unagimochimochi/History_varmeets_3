//
//  AppDelegate.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/02/26.
//

import UIKit
import CloudKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let firstUserDefaults = UserDefaults.standard
        let firstLaunchKey = "firstLaunch"
        let firstLaunch = [firstLaunchKey: true]
        firstUserDefaults.register(defaults: firstLaunch)
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        if let id = myID {
            
            let predicate = NSPredicate(format: "destination == %@", argumentArray: [id])
            let subscription = CKQuerySubscription(recordType: "Notifications", predicate: predicate, options: .firesOnRecordUpdate)
            
            let info = CKSubscription.NotificationInfo()
            
            info.titleLocalizationKey = "%1$@"
            info.titleLocalizationArgs = ["notificationTitle"]
            info.alertLocalizationKey = "%1$@"
            info.alertLocalizationArgs = ["notificationContent"]
            
            info.soundName = "default"
            
            subscription.notificationInfo = info
            
            let publicDatabase = CKContainer.default().publicCloudDatabase
            
            publicDatabase.save(subscription, completionHandler: {(subscription, error) in
                
                if let error = error {
                    print("サブスクリプション保存エラー: \(error)")
                    return
                }
                print("サブスクリプション保存成功")
            })
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
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

}



extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // アプリが起動しているとき
        func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            
            if #available(iOS 14.0, *) {
                completionHandler([.sound, .banner])
            } else {
                completionHandler([.sound])
            }
        }
        
        // アプリが起動していないとき
        func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
            
            completionHandler()
        }
    
}

