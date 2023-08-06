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
    @Published var updated = false
    @Published var showAlert = false
    @Published var risString = ""
    
    @Published var selectedTab = ToBeCitedTab.articles
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
    
    init(persistence: Persistence) {
        self.persistence = persistence
        self.persistenceHelper = PersistenceHelper(persistence: persistence)
        
        super.init()
        
        NotificationCenter.default
          .publisher(for: .NSPersistentStoreRemoteChange)
          .sink { self.fetchUpdates($0) }
          .store(in: &subscriptions)
        
        $updated
            .debounce(for: 5.0, scheduler: RunLoop.main)
            .sink { _ in
                self.logger.log("Remote updates in progress")
                self.fetchAll()
            }
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
        
        fetchAll()
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
            .compactMap { $0.article }
        
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
    @Published var allArticles = [Article]()
    @Published var authors = [Author]()
    @Published var allAuthors = [Author]()
    @Published var collections = [Collection]()
    @Published var allCollections = [Collection]()
    
    func fetchAll() {
        fetchArticles()
        fetchAuthors()
        fetchCollections()
    }
    
    func fetchArticles() {
        let fetchRequest = NSFetchRequest<Article>(entityName: "Article")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Article.published, ascending: false),
                                        NSSortDescriptor(keyPath: \Article.title, ascending: true)]
        articles = persistenceHelper.perform(fetchRequest)
    }
    
    func fetchAllArticles() {
        let fetchRequest = NSFetchRequest<Article>(entityName: "Article")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Article.published, ascending: false)]
        allArticles = persistenceHelper.perform(fetchRequest)
    }
    
    func fetchAuthors() {
        let fetchRequest = NSFetchRequest<Author>(entityName: "Author")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Author.lastName, ascending: true),
                                        NSSortDescriptor(keyPath: \Author.firstName, ascending: true),
                                        NSSortDescriptor(keyPath: \Author.created, ascending: false)]
        authors = persistenceHelper.perform(fetchRequest)
    }
    
    func fetchAllAuthors() {
        let fetchRequest = NSFetchRequest<Author>(entityName: "Author")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Author.lastName, ascending: true),
                                        NSSortDescriptor(keyPath: \Author.firstName, ascending: true),
                                        NSSortDescriptor(keyPath: \Author.created, ascending: false)]
        allAuthors = persistenceHelper.perform(fetchRequest)
    }
    
    func fetchCollections() {
        let fetchRequest = NSFetchRequest<Collection>(entityName: "Collection")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Collection.name, ascending: true)]
        collections = persistenceHelper.perform(fetchRequest)
    }
    
    func fetchAllColections() {
        let fetchRequest = NSFetchRequest<Collection>(entityName: "Collection")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Collection.name, ascending: true)]
        allCollections = persistenceHelper.perform(fetchRequest)
    }
    
    func save(completionHandler: ((Bool) -> Void)? = nil) -> Void {
        persistenceHelper.save { result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    completionHandler?(true)
                case .failure(let error):
                    self.logger.log("Error while saving data: \(error.localizedDescription, privacy: .public)")
                    self.showAlert.toggle()
                    completionHandler?(false)
                }
                
                if self.searchString.isEmpty {
                    self.fetchAll()
                }
            }
        }
    }
    
    func save(risRecords: [RISRecord]) -> Void {
        let created = Date()
        persistenceHelper.perform {
            risRecords.forEach { self.createEntities(from: $0, created: created) }
            self.save()
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
    
    func add(contact: ContactDTO, to author: Author) -> Void {
        persistenceHelper.perform {
            let contactEntity = self.persistenceHelper.createAuthorContact(from: contact)
            author.addToContacts(contactEntity)
            self.save()
        }
    }
    
    func addCollection(_ name: String, articles: [Article]) -> Void {
        persistenceHelper.perform {
            let collection = self.persistenceHelper.create(collection: name, of: articles)
            
            for index in 0..<articles.count {
                collection.addToArticles(articles[index])
                let _ = self.persistenceHelper.createOrder(in: collection, for: articles[index], with: Int64(index))
            }
            
            self.save()
        }
    }
    
    func add(article: Article, to collections: [Collection]) -> Void {
        persistenceHelper.perform {
            collections.forEach { collection in
                let count = collection.articles == nil ? 0 : collection.articles!.count
                let _ = self.persistenceHelper.createOrder(in: collection, for: article, with: Int64(count))
                collection.addToArticles(article)
            }
            
            self.save { success in
                if !success {
                    self.logger.log("AddToCollectionsView: Failed to update")
                }
            }
        }
    }
    
    func add(references collections: [Collection], to article: Article) -> Void {
        persistenceHelper.perform {
            for collection in collections {
                collection.articles?.forEach { reference in
                    guard let reference = reference as? Article, reference != article else {
                        return
                    }
                    
                    guard let references = reference.references, !references.contains(article) else {
                        return
                    }
                    
                    reference.addToCited(article)
                    article.addToReferences(reference)
                }
            }
            
            self.save { success in
                if !success {
                    self.logger.log("ImportCollectionAsReferencesView: Failed to update")
                }
            }
        }
    }
    
    private func delete(_ object: NSManagedObject) -> Void {
        persistenceHelper.delete(object)
    }
    
    func delete(_ articles: [Article]) -> Void {
        persistenceHelper.perform {
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
                
                self.delete(article)
            }
            
            self.save { success in
                self.logger.log("Delete data: success=\(success)")
            }
        }
    }
    
    func delete(_ authors: [Author]) -> Void {
        persistenceHelper.perform {
            authors.forEach { author in
                if author.articles == nil || author.articles!.count == 0 {
                    self.delete(author)
                }
            }
            self.save()
        }
    }
    
    func delete(_ contacts: [AuthorContact], from author: Author) -> Void {
        persistenceHelper.perform {
            contacts.forEach { contact in
                author.removeFromContacts(contact)
                self.delete(contact)
            }
            self.save()
        }
    }
    
    func delete(_ collections: [Collection]) -> Void {
        persistenceHelper.perform {
            collections.forEach { collection in
                collection.articles?.forEach { article in
                    if let article = article as? Article {
                        article.removeFromCollections(collection)
                    }
                }
                
                collection.orders?.forEach { order in
                    if let order = order as? OrderInCollection {
                        self.delete(order)
                    }
                }
                
                self.delete(collection)
            }
            
            self.save()
        }
    }
    
    func delete(_ orders: [OrderInCollection], at offsets: IndexSet, in collection: Collection) -> Void {
        persistenceHelper.perform {
            orders.forEach { order in
                order.article?.removeFromCollections(collection)
                self.delete(order)
            }
            
            if let offset = offsets.first {
                collection.orders?.forEach { order in
                    if let order = order as? OrderInCollection, order.order > offset {
                        order.order -= 1
                    }
                }
            }

            self.save()
        }
    }
    
    func rollback() -> Void {
        persistenceHelper.rollback()
    }
    
    // MARK: - Persistence History Request
    private lazy var historyRequestQueue = DispatchQueue(label: "history")
    private func fetchUpdates(_ notification: Notification) -> Void {
        persistence.fetchUpdates(notification) { _ in
            DispatchQueue.main.async {
                self.updated.toggle()
            }
        }
    }

    var articleCount: Int {
        return persistenceHelper.getCount(entityName: "Article")
    }
    
    var authorCount: Int {
        return persistenceHelper.getCount(entityName: "Author")
    }
    
    func findAuthors(by example: Author) -> [Author] {
        guard let lastName = example.lastName, let firstLetterOfFirstName = example.firstName?.first else {
            return [Author]()
        }
        
        let fetchRequest = Author.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "(lastName CONTAINS[cd] %@) AND (firstName BEGINSWITH[cd] %@)", argumentArray: [lastName, firstLetterOfFirstName.lowercased()])
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "firstName", ascending: true)]
        
        return persistenceHelper.perform(fetchRequest)
    }
    
    func merge(authors: [Author]) -> Void {
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
            
            delete(authors[index])
        }
        
        save()
    }
    
    func update(article: Article, with authors: [Author]) -> Void {
        logger.log("Updating article=\(article) with authors=\(authors)")
        article.authors?.forEach { author in
            if let author = author as? Author {
                author.removeFromArticles(article)
            }
        }
        
        authors.forEach { author in
            author.addToArticles(article)
        }

        save()
    }
    
    func update(collection: Collection, with articles: [Article]) -> Void {
        logger.log("Updating collection=\(collection) with articles=\(articles)")
        collection.orders?.forEach { order in
            if let order = order as? OrderInCollection {
                delete(order)
            }
        }
        logger.log("Deleted orders")
        collection.articles?.forEach { article in
            if let article = article as? Article {
                article.removeFromCollections(collection)
            }
        }
        logger.log("Removed articles")
        for index in 0..<articles.count {
            let article = articles[index]
            article.addToCollections(collection)
            
            let _ = persistenceHelper.createOrder(in: collection, for: article, with: Int64(index))
        }
        logger.log("Saving the update")
        save()
        
    }
        
    func add(_ articles: [Article], to collections: [Collection]) -> Void {
        collections.forEach { collection in
            var count = collection.articles == nil ? 0 : collection.articles!.count
            for article in articles {
                let _ = persistenceHelper.createOrder(in: collection, for: article, with: Int64(count))
                article.addToCollections(collection)
                count += 1
            }
        }
        save()
    }
    
    func log(_ message: String) -> Void {
        logger.log("\(message, privacy: .public)")
    }
    
    // MARK: - Spotlight
    private var spotlightFoundArticles: [CSSearchableItem] = []
    private var articleSearchQuery: CSSearchQuery?
    @Published var searchString = ""
    
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
    
    func searchArticle() -> Void {
        if searchString.isEmpty {
            articleSearchQuery?.cancel()
            fetchArticles()
        } else {
            searchArticles()
        }
    }
    
    private func searchArticles() {
        let escapedText = searchString.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let queryString = "(title == \"*\(escapedText)*\"cd) || (textContent == \"*\(escapedText)*\"cd)"
        
        articleSearchQuery = CSSearchQuery(queryString: queryString, attributes: ["title"])
        
        articleSearchQuery?.foundItemsHandler = { items in
            DispatchQueue.main.async {
                self.spotlightFoundArticles += items
            }
        }
        
        articleSearchQuery?.completionHandler = { error in
            if let error = error {
                self.logger.log("Searching \(self.searchString) came back with error: \(error.localizedDescription, privacy: .public)")
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
            return persistenceHelper.find(for: url) as? T
        }
    }
    
    func continueActivity(_ activity: NSUserActivity, completionHandler: @escaping (Article) -> Void) {
        logger.log("continueActivity: \(activity)")
        guard let info = activity.userInfo, let objectIdentifier = info[CSSearchableItemActivityIdentifier] as? String else {
            return
        }

        guard let objectURI = URL(string: objectIdentifier), let entity = persistenceHelper.find(for: objectURI) else {
            logger.log("Can't find an object with objectIdentifier=\(objectIdentifier)")
            return
        }
        
        logger.log("entity = \(entity)")
        
        DispatchQueue.main.async {
            if let article = entity as? Article {
                self.selectedTab = .articles
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    completionHandler(article)
                }
            }
        }
        
    }
    
}
