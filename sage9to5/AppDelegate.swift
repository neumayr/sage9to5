//
//  AppDelegate.swift
//  sage9to5
//
//  Created by Matthias Neumayr on 18.04.19.
//  Copyright © 2019 Matthias Neumayr. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

      // Onboarding
      if !UserDefaults.standard.bool(forKey: "didFinishOnboarding") {
        UserDefaults.standard.set(true, forKey: "didFinishOnboarding")
        UserDefaults.standard.set(false, forKey: "showBrowser")
        UserDefaults.standard.set("https://portal000000000.bpo-sage.de/mportal/", forKey: "url")

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "OnboardingStoryboard")
        self.window?.rootViewController = viewController
        self.window?.makeKeyAndVisible()
      }

      // Manage Push Notifications when app is running
      UNUserNotificationCenter.current().delegate = self

      // Request Push Notification permissions from User
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
        if granted {
          print("Notifications permission granted.")
        } else {
          print(error as Any)
        }
      }

      // Override point for customization after application launch.
      return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
      completionHandler([.alert, .sound])
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
