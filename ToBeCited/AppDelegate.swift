//
//  AppDelegate.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 6/8/22.
//

import Foundation
import UIKit
import os
import CloudKit
import CoreData

class AppDelegate: NSObject, UIApplicationDelegate {
    private let logger = Logger()
    
    private let subscriptionID = "article-updated"
    private let didCreateArticleSubscription = "didCreateArticleSubscription"
    private let recordType = "CD_Article"
    private let recordValueKey = "CD_title"
    
    private var tokenCache = [NotificationToken: CKServerChangeToken]()
    
    private var database: CKDatabase {
        CKContainer(identifier: ToBeCitedConstants.iCloudIdentifier.rawValue).privateCloudDatabase
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       
        logger.log("didFinishLaunchingWithOptions")
        UNUserNotificationCenter.current().delegate = self
        
        registerForPushNotifications()
        
        // TODO: - Remove or comment out after testing
        UserDefaults.standard.setValue(false, forKey: didCreateArticleSubscription)
        
        subscribe()

        return true
    }
    
    private func registerForPushNotifications() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
                guard granted else {
                    return
                }
                self?.getNotificationSettings()
            }
    }

    private func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                return
            }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    private func subscribe() {
        guard !UserDefaults.standard.bool(forKey: didCreateArticleSubscription) else {
            logger.log("alredy true: didCreateArticleSubscription=\(UserDefaults.standard.bool(forKey: self.didCreateArticleSubscription))")
            return
        }
        
        let fetchSubscriptionsOperation = CKFetchSubscriptionsOperation(subscriptionIDs: [subscriptionID])
        fetchSubscriptionsOperation.fetchSubscriptionsResultBlock = { result in
            switch result {
            case .success():
                self.logger.log("subscribe success to fetch subscriptions")
            case .failure(let error):
                self.logger.log("subscribe failed to find subscriptions: \(String(describing: error))")
            }
        }
        
        fetchSubscriptionsOperation.perSubscriptionResultBlock = { (subscriptionID, result) in
            if subscriptionID == self.subscriptionID {
                switch result {
                case .success(let subscription):
                    self.logger.log("subscribe found: \(String(describing: subscription))")
                    UserDefaults.standard.setValue(true, forKey: self.didCreateArticleSubscription)
                    self.logger.log("set: didCreateArticleSubscription=\(UserDefaults.standard.bool(forKey: self.didCreateArticleSubscription))")
                case .failure(let error):
                    self.logger.log("subscribe can't find: \(String(describing: error))")
                    self.addSubscription()
                }
            }
        }
        
        database.add(fetchSubscriptionsOperation)
    }
    
    private func addSubscription() {
        let subscription = CKDatabaseSubscription(subscriptionID: subscriptionID)
        subscription.recordType = recordType
        subscription.notificationInfo = CKSubscription.NotificationInfo()
                
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: nil)
        operation.qualityOfService = .utility
        operation.modifySubscriptionsResultBlock = { result in
            switch result {
            case .success():
                self.logger.log("setting: didCreateArticleSubscription=\(UserDefaults.standard.bool(forKey: self.didCreateArticleSubscription))")
                UserDefaults.standard.setValue(true, forKey: self.didCreateArticleSubscription)
                self.logger.log("set: didCreateLinkSubscription=\(UserDefaults.standard.bool(forKey: self.didCreateArticleSubscription))")
            case .failure(let error):
                self.logger.log("Failed to modify subscription: \(String(describing: error))")
                UserDefaults.standard.setValue(false, forKey: self.didCreateArticleSubscription)
            }
        }
        database.add(operation)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { String(format: "%02.2hhx", $0) }
        let token = tokenParts.joined()
        logger.log("Device Token: \(token)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logger.log("Failed to register: \(String(describing: error))")
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) else {
            logger.log("notification=failed")
            completionHandler(.failed)
            return
        }
        logger.log("notification=\(String(describing: notification))")
        if !notification.isPruned && notification.notificationType == .database {
            if let databaseNotification = notification as? CKDatabaseNotification, databaseNotification.subscriptionID == subscriptionID {
                logger.log("databaseNotification=\(String(describing: databaseNotification.subscriptionID))")
                
                let serverToken = try? NotificationToken.server.readToken()
                if serverToken != nil {
                    tokenCache[.zone] = serverToken
                }
                
                addDatabaseChangesOperation(serverToken: serverToken)
            }
        }
        
        completionHandler(.newData)
    }
    
    private func processRecord(_ record: CKRecord) {
        guard record.recordType == recordType else {
            return
        }
        
        guard let title = record.value(forKey: recordValueKey) as? String else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = ToBeCitedConstants.appName.rawValue
        content.body = title
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
        
        logger.log("Processed \(record)")
    }
    
    private func addDatabaseChangesOperation(serverToken: CKServerChangeToken?) -> Void {
        let dbChangesOperation = CKFetchDatabaseChangesOperation(previousServerChangeToken: serverToken)
        
        dbChangesOperation.recordZoneWithIDChangedBlock = { self.addZoneChangesOperation(zoneId: $0) }
        
        dbChangesOperation.changeTokenUpdatedBlock = { token in
            self.tokenCache[.server] = token
        }

        dbChangesOperation.fetchDatabaseChangesResultBlock = { result in
            switch result {
            case .success((let token, _)):
                try? NotificationToken.server.write(token)
            case .failure(let error):
                self.logger.log("Failed to fetch database changes: \(String(describing: error))")
                if let lastToken = self.tokenCache[.server] {
                    try? NotificationToken.server.write(lastToken)
                }
            }
        }
        
        dbChangesOperation.qualityOfService = .utility
        database.add(dbChangesOperation)
    }
    
    private func addZoneChangesOperation(zoneId: CKRecordZone.ID) -> Void {
        let zoneToken = try? NotificationToken.zone.readToken()
        if zoneToken != nil {
            tokenCache[.zone] = zoneToken
        }
        
        var configurations = [CKRecordZone.ID: CKFetchRecordZoneChangesOperation.ZoneConfiguration]()
        let config = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        config.previousServerChangeToken = zoneToken
        configurations[zoneId] = config
        
        let zoneChangesOperation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneId], configurationsByRecordZoneID: configurations)
        
        zoneChangesOperation.recordWasChangedBlock = { recordID, result in
            switch(result) {
            case .success(let record):
                self.processRecord(record)
            case .failure(let error):
                self.logger.log("Failed to check if record was changed: recordID=\(recordID), error=\(String(describing: error))")
            }
        }
        
        zoneChangesOperation.recordZoneChangeTokensUpdatedBlock = { recordZoneID, token, _ in
            self.tokenCache[.zone] = token
        }
        
        zoneChangesOperation.recordZoneFetchResultBlock = { recordZoneID, result in
            switch(result) {
            case .success((let serverToken, _, _)):
                try? NotificationToken.zone.write(serverToken)
            case .failure(let error):
                self.logger.log("Failed to fetch record zone: recordZoneID=\(recordZoneID), error=\(String(describing: error))")
                if let lastToken = self.tokenCache[.zone] {
                    try? NotificationToken.zone.write(lastToken)
                }
            }
        }
        
        zoneChangesOperation.qualityOfService = .utility
        database.add(zoneChangesOperation)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        logger.info("userNotificationCenter: notification=\(notification)")
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
