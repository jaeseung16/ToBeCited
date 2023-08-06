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
        return persistence.createCoreSpotlightDelegate()
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
    
    func createrticle(from record: RISRecord, created at: Date) -> Article {
        let article = Article(context: viewContext)
        article.created = at
        article.title = record.primaryTitle ?? record.title
        article.journal = record.periodicalNameFullFormat ?? record.secondaryTitle
        article.abstract = record.abstract
        article.doi = record.doi
        article.volume = record.volumeNumber
        article.issueNumber = record.issueNumber
        article.startPage = record.startPage
        article.endPage = record.endPage
        article.uuid = UUID()
        
        // Need to parse DA or PY, Y1
        // newArticle.published = Date(from: record.date)
        article.published = determinePublished(recordDate: record.date, pulbicationYear: record.pulbicationYear, primaryDate: record.primaryDate)
        
        return article
    }
    
    func determinePublished(recordDate: String?, pulbicationYear: String?, primaryDate: String?) -> Date? {
        var published: Date?
        if let date = recordDate {
            let splitDate = date.split(separator: "/")
            if splitDate.count > 2 {
                published = getDate(from: splitDate)
            }
        } else if let pulbicationYear = pulbicationYear {
            let splitPY = pulbicationYear.split(separator: "/")
            if splitPY.count > 2 {
                published = getDate(from: splitPY)
            }
        } else if let primaryDate = primaryDate {
            let splitPrimaryDate = primaryDate.split(separator: "/")
            if splitPrimaryDate.count > 2 {
                published = getDate(from: splitPrimaryDate)
            }
        }
        return published
    }
    
    private func getDate(from yearMonthDate: [String.SubSequence]) -> Date? {
        var date: Date? = nil
        if let year = Int(yearMonthDate[0]), let month = Int(yearMonthDate[1]), let day = Int(yearMonthDate[2]) {
            date = DateComponents(calendar: Calendar(identifier: .iso8601), year: year, month: month, day: day).date
        }
        return date
    }
    
    func createAuthor(_ name: PersonNameComponents) -> Author {
        let author = Author(context: viewContext)
        author.created = Date()
        author.uuid = UUID()
        author.lastName = name.familyName
        author.firstName = name.givenName
        author.middleName = name.middleName
        author.nameSuffix = name.nameSuffix
        return author
    }
    
    func createRIS(from record: RISRecord) -> RIS {
        let writer = RISWriter(record: record)
        let ris = RIS(context: viewContext)
        ris.uuid = UUID()
        ris.content = writer.toString()
        return ris
    }
    
    func createAuthorContact(from dto: ContactDTO) -> AuthorContact {
        let authorContact = AuthorContact(context: viewContext)
        authorContact.created = Date()
        authorContact.email = dto.email
        authorContact.institution = dto.institution
        authorContact.address = dto.address
        return authorContact
    }
    
    func createOrder(in collection: Collection, for article: Article, with count: Int64) -> OrderInCollection {
        let order = OrderInCollection(context: viewContext)
        order.collectionId = collection.uuid
        order.articleId = article.uuid
        order.order = count
        collection.addToOrders(order)
        article.addToOrders(order)
        return order
    }
    
    func create(collection name: String, of articles: [Article]) -> Collection {
        let date = Date()
        let collection = Collection(context: viewContext)
        collection.name = name != "" ? name : ToBeCitedDateFormatter.collection.string(from: date)
        collection.uuid = UUID()
        collection.created = date
        collection.lastupd = date
        return collection
    }
    
    func rollback() {
        viewContext.rollback()
    }
    
    func getCount(entityName: String) -> Int {
        return persistence.count(entityName)
    }
    
    func find(for url: URL) -> NSManagedObject? {
        guard let objectID = viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url) else {
            PersistenceHelper.logger.log("objectID is nil for url=\(url)")
            return nil
        }
        return viewContext.object(with: objectID)
    }
    
    func perform(_ block: @escaping () -> Void) -> Void {
        viewContext.perform(block)
    }
}
