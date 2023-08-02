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
import SwiftUI
import CoreSpotlight

class ToBeCitedViewModel: NSObject, ObservableObject {
    let logger = Logger()
    
    @AppStorage("ToBeCited.spotlightIndexing") private var spotlightIndexing: Bool = false
    
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
    
    private(set) var articleIndexer: ArticleSpotlightDelegate?
    
    private var persistenceContainer: NSPersistentCloudKitContainer {
        persistence.cloudContainer!
    }
    private let persistenceHelper: PersistenceHelper
    
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
        self.persistenceHelper = PersistenceHelper(persistence: persistence)
        
        super.init()
        
        NotificationCenter.default
          .publisher(for: .NSPersistentStoreRemoteChange)
          .sink { self.fetchUpdates($0) }
          .store(in: &subscriptions)
        
        self.persistence.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        self.spotlightIndexing = UserDefaults.standard.bool(forKey: "spotlight_indexing")
        
        if let articleIndexer: ArticleSpotlightDelegate = self.persistenceHelper.getSpotlightDelegate() {
            self.articleIndexer = articleIndexer
            self.toggleIndexing(self.articleIndexer, enabled: true)
            NotificationCenter.default.addObserver(self, selector: #selector(defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
        }
        
        if !spotlightIndexing {
            DispatchQueue.main.async {
                self.indexArticles()
                self.spotlightIndexing.toggle()
            }
        }
        
        fetchArticles()
    }
    
    @objc private func defaultsChanged() -> Void {
        logger.log("spotlightIndexing=\(self.spotlightIndexing, privacy: .public)")
        
        if !self.spotlightIndexing {
            DispatchQueue.main.async {
                self.toggleIndexing(self.articleIndexer, enabled: false)
                self.toggleIndexing(self.articleIndexer, enabled: true)
                self.spotlightIndexing.toggle()
            }
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
    @Published var articles = [Article]()
    
    func fetchArticles() {
        let fetchRequest = NSFetchRequest<Article>(entityName: "Article")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Article.published, ascending: false),
                                        NSSortDescriptor(keyPath: \Article.title, ascending: true)]
        articles = persistenceHelper.perform(fetchRequest)
    }
    
    func save(completionHandler: ((Bool) -> Void)? = nil) -> Void {
        persistenceHelper.save { result in
            switch result {
            case .success(_):
                DispatchQueue.main.async {
                    // Fetch entities
                    self.toggle.toggle()
                    if let completionHandler = completionHandler {
                        completionHandler(true)
                    }
                }
            case .failure(let error):
                self.logger.log("Error while saving data: \(error.localizedDescription, privacy: .public)")
                DispatchQueue.main.async {
                    self.showAlert.toggle()
                    if let completionHandler = completionHandler {
                        completionHandler(false)
                    }
                }
            }
        }
    }
    
    func save(risRecords: [RISRecord]) -> Void {
        let created = Date()
        risRecords.forEach { createEntities(from: $0, created: created) }
        save { success in
            self.logger.log("Saved data: success=\(success)")
        }
    }
    
    private func createEntities(from record: RISRecord, created at: Date) -> Void {
        let newArticle = persistenceHelper.createrticle(from: record, created: at)
        
        // Need to parse DA or PY, Y1
        // newArticle.published = Date(from: record.date)
        newArticle.published = persistenceHelper.determinePublished(recordDate: record.date, pulbicationYear: record.pulbicationYear, primaryDate: record.primaryDate)
        
        let parseStrategy = PersonNameComponents.ParseStrategy()
        if let primaryAuthor = record.primaryAuthor, let name = try? parseStrategy.parse(primaryAuthor) {
            let author = persistenceHelper.createAuthor(name)
            author.addToArticles(newArticle)
        }
        if let secondaryAuthor = record.secondaryAuthor, let name = try? parseStrategy.parse(secondaryAuthor) {
            let author = persistenceHelper.createAuthor(name)
            author.addToArticles(newArticle)
        }
        if let tertiaryAuthor = record.tertiaryAuthor, let name = try? parseStrategy.parse(tertiaryAuthor) {
            let author = persistenceHelper.createAuthor(name)
            author.addToArticles(newArticle)
        }
        if let subsidiaryAuthor = record.subsidiaryAuthor, let name = try? parseStrategy.parse(subsidiaryAuthor) {
            let author = persistenceHelper.createAuthor(name)
            author.addToArticles(newArticle)
        }
        for author in record.authors {
            if let name = try? parseStrategy.parse(author) {
                let author = persistenceHelper.createAuthor(name)
                author.addToArticles(newArticle)
            }
        }
        
        let ris = persistenceHelper.createRIS(from: record)
        ris.article = newArticle
    }
    
    func add(contact: ContactDTO, to author: Author, viewContext: NSManagedObjectContext) -> Void {
        let contactEntity = AuthorContact(context: viewContext)
        contactEntity.created = Date()
        contactEntity.email = contact.email
        contactEntity.institution = contact.institution
        contactEntity.address = contact.address
        
        author.addToContacts(contactEntity)
        save()
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
        
        save()
    }
    
    private func delete(_ object: NSManagedObject) -> Void {
        persistenceHelper.delete(object)
    }
    
    func delete(_ articles: [Article]) -> Void {
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
            
            delete(article)
        }
        
        save { success in
            self.logger.log("Delete data: success=\(success)")
        }
    }
    
    func delete(_ authors: [Author]) -> Void {
        authors.forEach {author in
            if author.articles == nil || author.articles!.count == 0 {
                persistenceHelper.delete(author)
            }
        }
        save()
    }
    
    func delete(_ contacts: [AuthorContact], from author: Author) -> Void {
        contacts.forEach { contact in
            author.removeFromContacts(contact)
            delete(contact)
        }
        save()
    }
    
    func delete(_ collections: [Collection]) -> Void {
        collections.forEach { collection in
            collection.articles?.forEach { article in
                if let article = article as? Article {
                    article.removeFromCollections(collection)
                }
            }
            
            collection.orders?.forEach { order in
                if let order = order as? OrderInCollection {
                    delete(order)
                }
            }
            
            delete(collection)
        }
        
        save()
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
        
        save()
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
        
        save()
        
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
        
        save()
    }
    
    func log(_ message: String) -> Void {
        logger.log("\(message)")
    }
    
    // MARK: - Spotlight
    private var spotlightFoundArticles: [CSSearchableItem] = []
    private var articleSearchQuery: CSSearchQuery?
    
    private func toggleIndexing(_ indexer: NSCoreDataCoreSpotlightDelegate?, enabled: Bool) {
        guard let indexer = indexer else { return }
        if enabled {
            indexer.startSpotlightIndexing()
        } else {
            indexer.stopSpotlightIndexing()
        }
    }
    
    private func indexArticles() -> Void {
        logger.log("Indexing \(self.articles.count, privacy: .public) articles")
        index<Article>(articles, indexName: ToBeCitedConstants.articleIndexName.rawValue)
    }
    
    private func index<T: NSManagedObject>(_ entities: [T], indexName: String) {
        let searchableItems: [CSSearchableItem] = entities.compactMap { (entity: T) -> CSSearchableItem? in
            guard let attributeSet = attributeSet(for: entity) else {
                self.logger.log("Cannot generate attribute set for \(entity, privacy: .public)")
                return nil
            }
            return CSSearchableItem(uniqueIdentifier: entity.objectID.uriRepresentation().absoluteString, domainIdentifier: ToBeCitedConstants.domainIdentifier.rawValue, attributeSet: attributeSet)
        }
        
        logger.log("Adding \(searchableItems.count) items to index=\(indexName, privacy: .public)")
        
        CSSearchableIndex(name: indexName).indexSearchableItems(searchableItems) { error in
            guard let error = error else {
                return
            }
            self.logger.log("Error while indexing \(T.self): \(error.localizedDescription, privacy: .public)")
        }
    }
    
    private func attributeSet(for object: NSManagedObject) -> CSSearchableItemAttributeSet? {
        if let article = object as? Article {
            let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
            attributeSet.title = article.title
            attributeSet.textContent = article.abstract
            attributeSet.displayName = article.title
            attributeSet.contentDescription = article.journal
            return attributeSet
        }
        return nil
    }
    
    func searchArticle(_ text: String) -> Void {
        if text.isEmpty {
            articleSearchQuery?.cancel()
            fetchArticles()
        } else {
            searchArticles(text)
        }
    }
    
    private func searchArticles(_ text: String) {
        let escapedText = text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let queryString = "(title == \"*\(escapedText)*\"cd) || (textContent == \"*\(escapedText)*\"cd)"
        
        articleSearchQuery = CSSearchQuery(queryString: queryString, attributes: ["title"])
        
        articleSearchQuery?.foundItemsHandler = { items in
            DispatchQueue.main.async {
                self.spotlightFoundArticles += items
            }
        }
        
        articleSearchQuery?.completionHandler = { error in
            if let error = error {
                self.logger.log("Searching \(text) came back with error: \(error.localizedDescription, privacy: .public)")
            } else {
                DispatchQueue.main.async {
                    self.fetchArticles(self.spotlightFoundArticles)
                    self.spotlightFoundArticles.removeAll()
                }
            }
        }
        
        articleSearchQuery?.start()
    }
    
    private func fetchArticles(_ items: [CSSearchableItem]) {
        logger.log("Fetching \(items.count) articles")
        let fetched: [Article] = fetch(items)
        logger.log("fetched.count=\(fetched.count)")
        articles = fetched.sorted(by: { article1, article2 in
            guard let created1 = article1.created else {
                return false
            }
            guard let created2 = article2.created else {
                return true
            }
            return created1 > created2
        })
        logger.log("Found \(self.articles.count) articles")
    }
    
    private func fetch<T: NSManagedObject>(_ items: [CSSearchableItem]) -> [T] {
        return items.compactMap { (item: CSSearchableItem) -> T? in
            guard let url = URL(string: item.uniqueIdentifier) else {
                self.logger.log("url is nil for item=\(item)")
                return nil
            }
            return find(for: url) as? T
        }
    }
    
    func find(for url: URL) -> NSManagedObject? {
        guard let objectID = persistence.container.viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url) else {
            self.logger.log("objectID is nil for url=\(url)")
            return nil
        }
        return persistence.container.viewContext.object(with: objectID)
    }
    
}
