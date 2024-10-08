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
    
    @AppStorage("ToBeCited.spotlightArticleIndexing") private var spotlightArticleIndexing: Bool = false
    @AppStorage("ToBeCited.spotlightAuthorIndexing") private var spotlightAuthorIndexing: Bool = false
    
    private var persistence: Persistence
    private let parser = RISParser()
    
    @Published var ordersInCollection = [OrderInCollection]()
    @Published var showAlert = false
    @Published var risString = ""
    
    @Published var selectedTab = ToBeCitedTab.articles
    @Published var selectedAuthors: Set<Author>?
    @Published var selectedPublishedIn: Int?
    
    var collection: Collection?
    var articlesInCollection: [Article]?
    
    private var subscriptions: Set<AnyCancellable> = []
    
    private(set) var articleIndexer: ArticleSpotlightDelegate?
    private(set) var authorIndexer: AuthorSpotlightDelegate?
    
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
        
        self.persistence.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        self.spotlightArticleIndexing = UserDefaults.standard.bool(forKey: "ToBeCited.spotlightArticleIndexing")
        self.spotlightAuthorIndexing = UserDefaults.standard.bool(forKey: "ToBeCited.spotlightAuthorIndexing")
        
        
        if let articleIndexer: ArticleSpotlightDelegate = self.persistenceHelper.getSpotlightDelegate(), let authorIndexer: AuthorSpotlightDelegate = self.persistenceHelper.getSpotlightDelegate() {
            self.articleIndexer = articleIndexer
            self.authorIndexer = authorIndexer
            self.toggleIndexing(self.articleIndexer, enabled: true)
            self.toggleIndexing(self.authorIndexer, enabled: true)
            NotificationCenter.default.addObserver(self, selector: #selector(defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
        }
        
        logger.log("spotlightArticleIndexing=\(self.spotlightArticleIndexing, privacy: .public)")
        if !spotlightArticleIndexing {
            DispatchQueue.main.async {
                self.indexArticles()
                self.spotlightArticleIndexing.toggle()
                
            }
        }
        
        logger.log("spotlightAuthorIndexing=\(self.spotlightAuthorIndexing, privacy: .public)")
        if !spotlightAuthorIndexing {
            DispatchQueue.main.async {
                self.indexAuthors()
                self.spotlightAuthorIndexing.toggle()
                
            }
        }
        
        fetchAll()
    }
    
    @objc private func defaultsChanged() -> Void {
        if !self.spotlightAuthorIndexing {
            DispatchQueue.main.async {
                self.toggleIndexing(self.articleIndexer, enabled: false)
                self.toggleIndexing(self.articleIndexer, enabled: true)
                self.spotlightArticleIndexing.toggle()
            }
        }
        if !self.spotlightAuthorIndexing {
            DispatchQueue.main.async {
                self.toggleIndexing(self.authorIndexer, enabled: false)
                self.toggleIndexing(self.authorIndexer, enabled: true)
                self.spotlightAuthorIndexing.toggle()
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
    
    private func populateOrders(from collection: Collection) -> [OrderInCollection] {
        let orders = collection.orders?.compactMap { $0 as? OrderInCollection } ?? [OrderInCollection]()
        return orders.sorted { $0.order < $1.order }
    }
    
    func check(article: Article, in collection: Collection) -> Bool {
        if collection != self.collection {
            ordersInCollection.removeAll()
            ordersInCollection = populateOrders(from: collection)
            self.articlesInCollection = ordersInCollection.filter { $0.article != nil }.map { $0.article! }
            self.collection = collection
        }
        
        if let articles = self.articlesInCollection {
            return articles.contains(article)
        }
        
        return false

    }
    
    // MARK: - Persistence
    @Published var articles = [Article]()
    @Published var allArticles = [Article]()
    @Published var authors = [Author]()
    @Published var allAuthors = [Author]()
    @Published var collections = [Collection]()
    @Published var allCollections = [Collection]()
    
    // read
    func fetchAll() {
        fetchArticles()
        fetchAuthors()
        fetchCollections()
        fetchAllArticles()
        fetchAllAuthors()
    }
    
    func fetchArticles() {
        let sortDescriptors = [NSSortDescriptor(keyPath: \Article.published, ascending: false),
                               NSSortDescriptor(keyPath: \Article.title, ascending: true)]
        let fetchRequest = persistenceHelper.getFetchRequest(for: Article.self, entityName: "Article", sortDescriptors: sortDescriptors)
        articles = persistenceHelper.fetch(fetchRequest)
    }
    
    func fetchAllArticles() {
        let sortDescriptors = [NSSortDescriptor(keyPath: \Article.published, ascending: false)]
        let fetchRequest = persistenceHelper.getFetchRequest(for: Article.self, entityName: "Article", sortDescriptors: sortDescriptors)
        allArticles = persistenceHelper.fetch(fetchRequest)
    }
    
    func fetchAuthors() {
        let sortDescriptors = [NSSortDescriptor(keyPath: \Author.lastName, ascending: true),
                               NSSortDescriptor(keyPath: \Author.firstName, ascending: true),
                               NSSortDescriptor(keyPath: \Author.created, ascending: false)]
        let fetchRequest = persistenceHelper.getFetchRequest(for: Author.self, entityName: "Author", sortDescriptors: sortDescriptors)
        authors = persistenceHelper.fetch(fetchRequest)
    }
    
    func fetchAllAuthors() {
        let sortDescriptors = [NSSortDescriptor(keyPath: \Author.lastName, ascending: true),
                               NSSortDescriptor(keyPath: \Author.firstName, ascending: true),
                               NSSortDescriptor(keyPath: \Author.created, ascending: false)]
        let fetchRequest = persistenceHelper.getFetchRequest(for: Author.self, entityName: "Author", sortDescriptors: sortDescriptors)
        allAuthors = persistenceHelper.fetch(fetchRequest)
    }
    
    func fetchCollections() {
        let sortDescriptors = [NSSortDescriptor(keyPath: \Collection.name, ascending: true)]
        let fetchRequest = persistenceHelper.getFetchRequest(for: Collection.self, entityName: "Collection", sortDescriptors: sortDescriptors)
        collections = persistenceHelper.fetch(fetchRequest)
    }
    
    func fetchAllColections() {
        let sortDescriptors = [NSSortDescriptor(keyPath: \Collection.name, ascending: true)]
        let fetchRequest = persistenceHelper.getFetchRequest(for: Collection.self, entityName: "Collection", sortDescriptors: sortDescriptors)
        allCollections = persistenceHelper.fetch(fetchRequest)
    }
    
    func saveAndFetch(completionHandler: ((Bool) -> Void)? = nil) -> Void {
        save() { success in
            completionHandler?(success)
            self.articleSearchString = ""
            self.authorSearchString = ""
            self.fetchAll()
        }
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
            }
        }
    }
    
    // create
    func save(risRecords: [RISRecord]) -> Void {
        let created = Date()
        persistenceHelper.perform {
            risRecords.forEach { self.createEntities(from: $0, created: created) }
            self.saveAndFetch()
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
    
    func add(collection name: String, of articles: [Article]) -> Void {
        persistenceHelper.perform {
            let collection = self.persistenceHelper.create(collection: name, of: articles)
            
            for index in 0..<articles.count {
                collection.addToArticles(articles[index])
                let _ = self.persistenceHelper.createOrder(in: collection, for: articles[index], with: Int64(index))
            }
            
            self.saveAndFetch()
        }
    }
    
    func add(article: Article, to collections: [Collection]) -> Void {
        persistenceHelper.perform {
            collections.forEach { collection in
                let count = collection.articles == nil ? 0 : collection.articles!.count
                let _ = self.persistenceHelper.createOrder(in: collection, for: article, with: Int64(count))
                collection.addToArticles(article)
            }
            
            self.saveAndFetch() { success in
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
            
            self.saveAndFetch() { success in
                if !success {
                    self.logger.log("ImportCollectionAsReferencesView: Failed to update")
                }
            }
        }
    }
    
    // delete
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
                
                self.deleteFromIndex(article: article)
                self.delete(article)
            }
            
            self.saveAndFetch() { success in
                self.logger.log("Delete data: success=\(success)")
            }
        }
    }
    
    func delete(_ authors: [Author]) -> Void {
        persistenceHelper.perform {
            authors.forEach { author in
                if author.articles == nil || author.articles!.count == 0 {
                    self.deleteFromIndex(author: author)
                    self.delete(author)
                }
            }
            self.saveAndFetch()
        }
    }
    
    func delete(_ contacts: [AuthorContact], from author: Author) -> Void {
        persistenceHelper.perform {
            contacts.forEach { contact in
                author.removeFromContacts(contact)
                self.delete(contact)
            }
            self.saveAndFetch()
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
            
            self.saveAndFetch()
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

            self.saveAndFetch()
        }
    }
    
    func rollback() -> Void {
        persistenceHelper.rollback()
    }
    
    // update
    func merge(authors: [Author]) -> Void {
        let toMerge = authors[0]
        
        for index in 1..<authors.count {
            authors[index].articles?.forEach { article in
                if let article = article as? Article {
                    toMerge.addToArticles(article)
                    authors[index].removeFromArticles(article)
                }
            }
            
            authors[index].contacts?.forEach { contact in
                if let contact = contact as? AuthorContact {
                    toMerge.addToContacts(contact)
                    authors[index].removeFromContacts(contact)
                }
            }
            
            if let orcid = authors[index].orcid, toMerge.orcid == nil {
                toMerge.orcid = orcid
            }
            
            deleteFromIndex(author: authors[index])
            delete(authors[index])
        }
        
        saveAndFetch()
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

        saveAndFetch()
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
        saveAndFetch()
        
    }
    
    func add(_ articles: [Article], to collections: [Collection]) -> Void {
        if !articles.isEmpty {
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
        
        let sortDescriptors = [NSSortDescriptor(key: "firstName", ascending: true)]
        let predicate = NSPredicate(format: "(lastName CONTAINS[cd] %@) AND (firstName BEGINSWITH[cd] %@)", argumentArray: [lastName, firstLetterOfFirstName.lowercased()])
        let fetchRequest = persistenceHelper.getFetchRequest(for: Author.self, entityName: "Author", sortDescriptors: sortDescriptors, predicate: predicate)
        return persistenceHelper.fetch(fetchRequest)
    }
    
    // MARK: - Persistence History Request
    private func fetchUpdates(_ notification: Notification) -> Void {
        persistence.fetchUpdates(notification) { _ in
            DispatchQueue.main.async {
                self.logger.log("Called persistence.fetchUpdates")
            }
        }
    }
    
    func log(_ message: String) -> Void {
        logger.log("\(message, privacy: .public)")
    }
    
    func articles(titleIncluding string: String) -> [Article] {
        return allArticles.filter {
            if string == "" {
                return true
            } else if let title = $0.title {
                return title.range(of: string, options: .caseInsensitive) != nil
            } else {
                return false
            }
        }
    }
    
    func authors(lastNameIncluding string: String) -> [Author] {
        return allAuthors.filter { author in
            if string == "" {
                return true
            } else if let lastName = author.lastName {
                return lastName.range(of: string, options: .caseInsensitive) != nil
            } else {
                return false
            }
        }
    }
    
    // MARK: - Spotlight
    private var spotlightFoundArticles: [CSSearchableItem] = []
    private var spotlightFoundAuthors: [CSSearchableItem] = []
    private var articleSearchQuery: CSSearchQuery?
    private var authorSearchQuery: CSSearchQuery?
    @Published var articleSearchString = ""
    @Published var authorSearchString = ""
    
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
    
    private func indexAuthors() -> Void {
        logger.log("Indexing \(self.authors.count, privacy: .public) authors")
        index<Author>(authors, indexName: ToBeCitedConstants.authorIndexName.rawValue)
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
    
    private func deleteFromIndex(article: Article) -> Void {
        logger.log("Remove \(article, privacy: .public) from the index")
        remove<Article>(article, from: ToBeCitedConstants.articleIndexName.rawValue)
    }
    
    private func deleteFromIndex(author: Author) -> Void {
        logger.log("Remove \(author, privacy: .public) from the index")
        remove<Author>(author, from: ToBeCitedConstants.authorIndexName.rawValue)
    }
    
    private func remove<T: NSManagedObject>(_ entity: T, from indexName: String) -> Void {
        let identifier = entity.objectID.uriRepresentation().absoluteString
        
        CSSearchableIndex(name: indexName).deleteSearchableItems(withIdentifiers: [identifier]) { error in
            self.logger.log("Can't delete an item with identifier=\(identifier, privacy: .public)")
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
        if let author = object as? Author {
            let authorName = ToBeCitedNameFormatHelper.formatName(of: author)
            let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
            attributeSet.title = authorName
            attributeSet.displayName = authorName
            return attributeSet
        }
        return nil
    }
    
    func searchArticle() -> Void {
        if articleSearchString.isEmpty {
            articleSearchQuery?.cancel()
            fetchArticles()
        } else {
            searchArticles()
        }
    }
    
    private func searchArticles() {
        let escapedText = articleSearchString.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let queryString = "(title == \"*\(escapedText)*\"cd) || (textContent == \"*\(escapedText)*\"cd)"
        
        articleSearchQuery = CSSearchQuery(queryString: queryString, attributes: ["title", "textContent"])
        
        articleSearchQuery?.foundItemsHandler = { items in
            DispatchQueue.main.async {
                self.spotlightFoundArticles += items
            }
        }
        
        articleSearchQuery?.completionHandler = { error in
            if let error = error {
                self.logger.log("Searching \(self.articleSearchString) came back with error: \(error.localizedDescription, privacy: .public)")
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
        let fetched = fetch(Article.self, items)
        logger.log("fetched.count=\(fetched.count)")
        articles = fetched.sorted(by: { article1, article2 in
            guard let published1 = article1.published else {
                return false
            }
            guard let published2 = article2.published else {
                return true
            }
            return published1 > published2
        })
        logger.log("Found \(self.articles.count) articles")
    }
    
    func searchAuthor() -> Void {
        if authorSearchString.isEmpty {
            authorSearchQuery?.cancel()
            fetchAuthors()
        } else {
            searchAuthors()
        }
    }
    
    private func searchAuthors() {
        let escapedText = authorSearchString.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let queryString = "(title == \"*\(escapedText)*\"cd)"
        logger.log("searchAuthors: \(queryString, privacy: .public)")
        authorSearchQuery = CSSearchQuery(queryString: queryString, attributes: ["title"])
        
        authorSearchQuery?.foundItemsHandler = { items in
            DispatchQueue.main.async {
                self.spotlightFoundAuthors += items
            }
        }
        
        authorSearchQuery?.completionHandler = { error in
            if let error = error {
                self.logger.log("Searching \(self.authorSearchString) came back with error: \(error.localizedDescription, privacy: .public)")
            } else {
                DispatchQueue.main.async {
                    self.fetchAuthors(self.spotlightFoundAuthors)
                    self.spotlightFoundAuthors.removeAll()
                }
            }
        }
        
        authorSearchQuery?.start()
    }
    
    private func fetchAuthors(_ items: [CSSearchableItem]) {
        logger.log("Fetching \(items.count) authors")
        let fetched = fetch(Author.self, items)
        logger.log("fetched.count=\(fetched.count)")
        authors = fetched.sorted(by: < )
        logger.log("Found \(self.authors.count) authors")
    }
    
    private func fetch<Element>(_ type: Element.Type, _ items: [CSSearchableItem]) -> [Element] where Element: NSManagedObject {
        return items.compactMap { (item: CSSearchableItem) -> Element? in
            guard let url = URL(string: item.uniqueIdentifier) else {
                self.logger.log("url is nil for item=\(item)")
                return nil
            }
            return persistenceHelper.find(for: url) as? Element
        }
    }
    
    // TODO:
    func continueActivity(_ activity: NSUserActivity, completionHandler: @escaping (NSManagedObject) -> Void) {
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
            } else if let author = entity as? Author {
                self.selectedTab = .authors
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    completionHandler(author)
                }
            }
        }
    }
    
}
