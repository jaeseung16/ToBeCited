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
    private let parser = RISParser()
    
    @Published var ordersInCollection = [OrderInCollection]()
    
    var collection: Collection?
    var articlesInCollection: [Article]?
    
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
    
    func parse(risString: String) -> [RISRecord]? {
        try? parser.parse(risString)
    }
    
    @Published var stringToExport: String = ""
    
    func export(collection: Collection, with order: ExportOrder = .dateEnd) -> Void {
        let articles = collection.orders?
            .map { $0 as! OrderInCollection }
            .sorted(by: { $0.order < $1.order })
            .map { $0.article }
            .filter { $0 != nil }
            .map { $0! }
        
        guard let articles = articles else {
            return
        }
        
        var result = ""
        
        for article in articles {
            if let risString = article.ris?.content {
                if let ris = parse(risString: risString), !ris.isEmpty {
                    switch order {
                    case .dateFirst:
                        result += ris[0].dateFirstDescription
                    case .dateMiddle:
                        result += ris[0].dateMiddleDescription
                    case .dateEnd:
                        result += ris[0].description
                    }
                }
            }
            result += "\n"
        }
        
        stringToExport = result
    }
    
    func populateOrders(from collection: Collection) -> Void {
        var orders = [OrderInCollection]()

        collection.orders?.forEach { order in
            if let order = order as? OrderInCollection {
                orders.append(order)
            }
        }
        
        ordersInCollection.removeAll()
        ordersInCollection = orders.sorted { $0.order < $1.order }
        
        self.articlesInCollection = ordersInCollection.filter { $0.article != nil }.map { $0.article! }
        self.collection = collection
    }
    
    func check(article: Article, in collection: Collection) -> Bool {
        if collection != self.collection {
            populateOrders(from: collection)
        }
        
        if let articles = self.articlesInCollection {
            return articles.contains(article)
        }
        
        return false

    }
    
    func nameComponents(of author: Author) -> PersonNameComponents {
        return PersonNameComponents(givenName: author.firstName,
                                    middleName: author.middleName,
                                    familyName: author.lastName,
                                    nameSuffix: author.nameSuffix)
    }
    
    func populate(author: Author, with components: PersonNameComponents) {
        author.lastName = components.familyName
        author.firstName = components.givenName
        author.middleName = components.middleName
        author.nameSuffix = components.nameSuffix
    }
}
