//
//  ToBeCitedViewModel.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/14/21.
//

import Foundation
import CoreData
import Combine
import os
import Persistence

class ToBeCitedViewModel: NSObject, ObservableObject {
    let logger = Logger()
    
    private var persistence: Persistence
    private let parser = RISParser()
    
    @Published var ordersInCollection = [OrderInCollection]()
    @Published var toggle = false
    @Published var showAlert = false
    @Published var risString = ""
    
    @Published var selectedAuthors: Set<Author>?
    @Published var selectedPublishedIn: Int?
    
    var collection: Collection?
    var articlesInCollection: [Article]?
    
    private var subscriptions: Set<AnyCancellable> = []
    
    private var persistenceContainer: NSPersistentCloudKitContainer {
        persistence.container
    }
    
    var yearOnlyDateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        return dateFormatter
    }
    
    private var collectionDateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        return dateFormatter
    }
    
    init(persistence: Persistence) {
        self.persistence = persistence
        
        super.init()
        
        NotificationCenter.default
          .publisher(for: .NSPersistentStoreRemoteChange)
          .sink { self.fetchUpdates($0) }
          .store(in: &subscriptions)
        
        self.persistence.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
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
        var count = 1
        for article in articles {
            if let risString = article.ris?.content {
                if let ris = parse(risString: risString), !ris.isEmpty {
                    result += "\(count);"
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
            count += 1
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
    
    func journalString(article: Article) -> String {
        guard let journalTitle = article.journal else {
            return "Journal title is not available"
        }
        
        var journalString = journalTitle
        if let volume = article.volume {
            journalString.append(" " + volume)
            if let startPage = article.startPage {
                journalString.append(", " + startPage)
                if let endPage = article.endPage {
                    journalString.append("-" + endPage)
                }
            }
        }
        return journalString
    }
    
    // MARK: - Persistence
    func save(viewContext: NSManagedObjectContext, completionHandler: ((Bool) -> Void)?) -> Void {
        persistence.save { result in
            switch result {
            case .success(_):
                DispatchQueue.main.async {
                    self.toggle.toggle()
                    if completionHandler != nil {
                        completionHandler!(true)
                    }
                }
            case .failure(let error):
                self.logger.log("Error while saving data: \(error.localizedDescription, privacy: .public)")
                self.logger.log("Error while saving data: \(Thread.callStackSymbols, privacy: .public)")
                print("Error while saving data: \(Thread.callStackSymbols)")
                DispatchQueue.main.async {
                    self.showAlert.toggle()
                    if completionHandler != nil {
                        completionHandler!(false)
                    }
                }
            }
        }
    }
    
    func save(risRecords: [RISRecord], viewContext: NSManagedObjectContext) -> Void {
        let created = Date()
        
        for record in risRecords {
            let newArticle = Article(context: viewContext)
            newArticle.created = created
            newArticle.title = record.primaryTitle ?? record.title
            newArticle.journal = record.periodicalNameFullFormat ?? record.secondaryTitle
            newArticle.abstract = record.abstract
            newArticle.doi = record.doi
            newArticle.volume = record.volumeNumber
            newArticle.issueNumber = record.issueNumber
            newArticle.startPage = record.startPage
            newArticle.endPage = record.endPage
            newArticle.uuid = UUID()
            
            // Need to parse DA or PY, Y1
            // newArticle.published = Date(from: record.date)
            var published: Date?
            if let date = record.date {
                let splitDate = date.split(separator: "/")
                if splitDate.count > 2 {
                    published = getDate(from: splitDate)
                }
            } else if let pulbicationYear = record.pulbicationYear {
                let splitPY = pulbicationYear.split(separator: "/")
                if splitPY.count > 2 {
                    published = getDate(from: splitPY)
                }
            } else if let primaryDate = record.primaryDate {
                let splitPrimaryDate = primaryDate.split(separator: "/")
                if splitPrimaryDate.count > 2 {
                    published = getDate(from: splitPrimaryDate)
                }
            }
            newArticle.published = published
            
            let parseStrategy = PersonNameComponents.ParseStrategy()
            if let primaryAuthor = record.primaryAuthor, let name = try? parseStrategy.parse(primaryAuthor) {
                createAuthorEntity(name, article: newArticle, viewContext: viewContext)
            }
            if let secondaryAuthor = record.secondaryAuthor, let name = try? parseStrategy.parse(secondaryAuthor) {
                createAuthorEntity(name, article: newArticle, viewContext: viewContext)
            }
            if let tertiaryAuthor = record.tertiaryAuthor, let name = try? parseStrategy.parse(tertiaryAuthor) {
                createAuthorEntity(name, article: newArticle, viewContext: viewContext)
            }
            if let subsidiaryAuthor = record.subsidiaryAuthor, let name = try? parseStrategy.parse(subsidiaryAuthor) {
                createAuthorEntity(name, article: newArticle, viewContext: viewContext)
            }
            for author in record.authors {
                if let name = try? parseStrategy.parse(author) {
                    createAuthorEntity(name, article: newArticle, viewContext: viewContext)
                }
            }
            
            let writer = RISWriter(record: record)
            let ris = RIS(context: viewContext)
            ris.uuid = UUID()
            ris.content = writer.toString()
            ris.article = newArticle
        }
        
        save(viewContext: viewContext) { success in
            self.logger.log("Saved data: success=\(success)")
        }
    }
    
    private func getDate(from yearMonthDate: [String.SubSequence]) -> Date? {
        var date: Date? = nil
        if let year = Int(yearMonthDate[0]), let month = Int(yearMonthDate[1]), let day = Int(yearMonthDate[2]) {
            date = DateComponents(calendar: Calendar(identifier: .iso8601), year: year, month: month, day: day).date
        }
        return date
    }
    
    private func createAuthorEntity(_ authorName: PersonNameComponents, article: Article, viewContext: NSManagedObjectContext) -> Void {
        let authorEntity = Author(context: viewContext)
        authorEntity.created = Date()
        authorEntity.uuid = UUID()

        populate(author: authorEntity, with: authorName)

        authorEntity.addToArticles(article)
    }
    
    private func populate(author: Author, with components: PersonNameComponents) {
        author.lastName = components.familyName
        author.firstName = components.givenName
        author.middleName = components.middleName
        author.nameSuffix = components.nameSuffix
    }
    
    func add(contact: ContactDTO, to author: Author, viewContext: NSManagedObjectContext) -> Void {
        let contactEntity = AuthorContact(context: viewContext)
        contactEntity.created = Date()
        contactEntity.email = contact.email
        contactEntity.institution = contact.institution
        contactEntity.address = contact.address
        
        author.addToContacts(contactEntity)
        save(viewContext: viewContext, completionHandler: nil)
    }
    
    func addCollection(_ name: String, articles: [Article], viewContext: NSManagedObjectContext) -> Void {
        let date = Date()
        
        let collection = Collection(context: viewContext)
        collection.name = name != "" ? name : collectionDateFormatter.string(from: date)
        collection.uuid = UUID()
        collection.created = date
        collection.lastupd = date
        
        for index in 0..<articles.count {
            collection.addToArticles(articles[index])
            
            let orderInCollection = OrderInCollection(context: viewContext)
            orderInCollection.collectionId = collection.uuid
            orderInCollection.articleId = articles[index].uuid
            orderInCollection.order = Int64(index)
            orderInCollection.collection = collection
            orderInCollection.article = articles[index]
        }
        
        save(viewContext: viewContext, completionHandler: nil)
    }
    
    func delete(_ articles: [Article], viewContext: NSManagedObjectContext) -> Void {
        viewContext.perform {
            articles.forEach { article in
                article.collections?.forEach { collection in
                    if let collection = collection as? Collection {
                        article.removeFromCollections(collection)
                    }
                }
                      
                // TODO: Reorder articles in collection
                // TODO: Move these operations to viewModel
                      
                article.orders?.forEach { order in
                    if let order = order as? OrderInCollection {
                        article.removeFromOrders(order)
                    }
                }
                
                viewContext.delete(article)
            }
            
            self.save(viewContext: viewContext) { success in
                self.logger.log("Delete data: success=\(success)")
            }
        }
    }
    
    func delete(_ authors: [Author], viewContext: NSManagedObjectContext) -> Void {
        viewContext.perform {
            authors.forEach {author in
                if author.articles == nil || author.articles!.count == 0 {
                    viewContext.delete(author)
                }
            }
            self.save(viewContext: viewContext, completionHandler: nil)
        }
    }
    
    func delete(_ contacts: [AuthorContact], from author: Author, viewContext: NSManagedObjectContext) -> Void {
        viewContext.perform {
            contacts.forEach { contact in
                author.removeFromContacts(contact)
                viewContext.delete(contact)
            }
            self.save(viewContext: viewContext, completionHandler: nil)
        }
    }
    
    func delete(_ collections: [Collection], viewContext: NSManagedObjectContext) -> Void {
        viewContext.perform {
            collections.forEach { collection in
                collection.articles?.forEach { article in
                    if let article = article as? Article {
                        article.removeFromCollections(collection)
                    }
                }
                
                collection.orders?.forEach { order in
                    if let order = order as? OrderInCollection {
                        viewContext.delete(order)
                    }
                }
                
                viewContext.delete(collection)
            }
            
            self.save(viewContext: viewContext, completionHandler: nil)
        }
    }
    
    // MARK: - Persistence History Request
    private lazy var historyRequestQueue = DispatchQueue(label: "history")
    private func fetchUpdates(_ notification: Notification) -> Void {
        persistence.fetchUpdates(notification) { _ in
            DispatchQueue.main.async {
                self.toggle.toggle()
            }
        }
    }

    var articleCount: Int {
        return getCount(entityName: "Article")
    }
    
    var authorCount: Int {
        return getCount(entityName: "Author")
    }
    
    private func getCount(entityName: String) -> Int {
        var count = 0
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        do {
            count = try persistenceContainer.viewContext.count(for: fetchRequest)
        } catch {
            print("Can't count \(entityName): \(error.localizedDescription)")
        }
        return count
    }
    
    func merge(authors: [Author], viewContext: NSManagedObjectContext) -> Void {
        let toMerge = authors[0]
        
        for index in 1..<authors.count {
            authors[index].articles?.forEach({ article in
                if let article = article as? Article {
                    toMerge.addToArticles(article)
                    authors[index].removeFromArticles(article)
                }
            })
            
            authors[index].contacts?.forEach { contact in
                if let contact = contact as? AuthorContact {
                    toMerge.addToContacts(contact)
                    authors[index].removeFromContacts(contact)
                }
            }
            
            if let orcid = authors[index].orcid, toMerge.orcid == nil {
                toMerge.orcid = orcid
            }
            
            viewContext.delete(authors[index])
        }
        
        save(viewContext: viewContext, completionHandler: nil)
    }
    
    func update(collection: Collection, with articles: [Article], viewContext: NSManagedObjectContext) -> Void {
        collection.orders?.forEach { order in
            if let order = order as? OrderInCollection {
                viewContext.delete(order)
            }
        }
        
        collection.articles?.forEach { article in
            if let article = article as? Article {
                article.removeFromCollections(collection)
            }
        }
        
        for index in 0..<articles.count {
            let article = articles[index]
            article.addToCollections(collection)
            
            let order = OrderInCollection(context: viewContext)
            order.collectionId = collection.uuid
            order.articleId = article.uuid
            order.order = Int64(index)
            collection.addToOrders(order)
            article.addToOrders(order)
        }
        
        save(viewContext: viewContext, completionHandler: nil)
        
    }
        
    func add(_ articles: [Article], to collections: [Collection], viewContext: NSManagedObjectContext) -> Void {
        for collection in collections {
            var count = collection.articles == nil ? 0 : collection.articles!.count
            
            for article in articles {
                let order = OrderInCollection(context: viewContext)
                order.collectionId = collection.uuid
                order.articleId = article.uuid
                order.order = Int64(count)
                collection.addToOrders(order)
                article.addToOrders(order)
                
                article.addToCollections(collection)
                count += 1
            }
        }
        
        save(viewContext: viewContext, completionHandler: nil)
    }
    
    func log(_ message: String) -> Void {
        logger.log("\(message)")
    }
}
