//
//  ToBeCitedViewModel.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/14/21.
//

import Foundation
import CoreData

class ToBeCitedViewModel: NSObject, ObservableObject {
    static let shared = ToBeCitedViewModel()
    
    private let persistenteContainer = PersistenceController.shared.container
    
    override init() {
        super.init()
    }
    
    func save(viewContext: NSManagedObjectContext) -> Void {
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
