//
//  PersistenceHelper.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 7/30/23.
//

import Foundation
import CoreData
import os
import Persistence

class PersistenceHelper {
    private static let logger = Logger()
    
    private let persistence: Persistence
    var viewContext: NSManagedObjectContext {
        persistence.container.viewContext
    }
    
    init(persistence: Persistence) {
        self.persistence = persistence
    }
    
    func perform<Element>(_ fetchRequest: NSFetchRequest<Element>) -> [Element] {
        var fetchedEntities = [Element]()
        do {
            fetchedEntities = try viewContext.fetch(fetchRequest)
        } catch {
            PersistenceHelper.logger.error("Failed to fetch with fetchRequest=\(fetchRequest, privacy: .public): error=\(error.localizedDescription, privacy: .public)")
        }
        return fetchedEntities
    }
    
    func getSpotlightDelegate<T: NSCoreDataCoreSpotlightDelegate>() -> T? {
        if let persistentStoreDescription = self.persistence.container.persistentStoreDescriptions.first {
            return T(forStoreWith: persistentStoreDescription, coordinator: self.persistence.container.persistentStoreCoordinator)
        }
        PersistenceHelper.logger.log("Returning nil")
        return nil
    }
    
    func save(completionHandler: @escaping (Result<Void,Error>) -> Void) -> Void {
        persistence.save { result in
            switch result {
            case .success(_):
                completionHandler(.success(()))
            case .failure(let error):
                PersistenceHelper.logger.log("Error while saving data: \(Thread.callStackSymbols, privacy: .public)")
                completionHandler(.failure(error))
            }
        }
    }
    
    func delete(_ object: NSManagedObject) -> Void {
        viewContext.delete(object)
    }
    
}