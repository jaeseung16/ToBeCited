//
//  Persistence.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/17/21.
//

import CoreData
import os

struct PersistenceController {
    static let shared = PersistenceController()
    static let logger = Logger()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newArticle = Article(context: viewContext)
            newArticle.created = Date()
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "ToBeCited")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description?.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.resonance.jlee.ToBeCited")
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                if let error = error as NSError? {
                    if let error = error as NSError? {
                        PersistenceController.logger.error("Could not load persistent store: \(storeDescription), \(error), \(error.userInfo)")
                    }
                }
            }
        })
        
        print("persistentStores = \(container.persistentStoreCoordinator.persistentStores)")
        container.viewContext.name = "ToBeCited"
        purgeHistory()
    }
    
    private func purgeHistory() {
        let sevenDaysAgo = Date(timeIntervalSinceNow: TimeInterval(exactly: -604_800)!)
        let purgeHistoryRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: sevenDaysAgo)

        do {
            try container.newBackgroundContext().execute(purgeHistoryRequest)
        } catch {
            if let error = error as NSError? {
                PersistenceController.logger.error("Could not purge history: \(error), \(error.userInfo)")
            }
        }
    }
}
