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

@MainActor
class ToBeCitedViewModel: NSObject, ObservableObject {
    let logger = Logger()
    
    @AppStorage("ToBeCited.spotlightArticleIndexing") private var spotlightArticleIndexing: Bool = false
    
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
    
    private let spotlightHelper: SpotlightHelper
    
    private let persistenceHelper: PersistenceHelper
    
    init(persistence: Persistence) {
        self.persistence = persistence
        self.persistence.container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        self.persistenceHelper = PersistenceHelper(persistence: persistence)
        
        self.spotlightArticleIndexing = UserDefaults.standard.bool(forKey: "ToBeCited.spotlightArticleIndexing")
        
        self.spotlightHelper = SpotlightHelper(persistenceHelper: persistenceHelper)
        
        super.init()
        
        fetchAll()
        
        if UserDefaults.standard.bool(forKey: "ToBeCited.spotlightAuthorIndexing") {
            UserDefaults.standard.removeObject(forKey: "ToBeCited.spotlightAuthorIndexing")
            
            self.spotlightArticleIndexing = false
            Task {
                await self.spotlightHelper.removeAuthorsFromIndex()
            }
        }
        
        logger.log("spotlightArticleIndexing=\(self.spotlightArticleIndexing, privacy: .public)")
        if !spotlightArticleIndexing {
            Task {
                let articleAttributeSets = self.articles.compactMap {
                    SpotlightAttributeSet(uid: $0.objectID.uriRepresentation().absoluteString,
                                          title: $0.title,
                                          textContent: $0.abstract,
                                          displayName: $0.title,
                                          contentDescription: $0.journal)
                }
                
                await self.spotlightHelper.index(articleAttributeSets)
                
                let authorAttributeSets = self.authors.compactMap {
                    let authorName = ToBeCitedNameFormatHelper.formatName(of: $0)
                    return SpotlightAttributeSet(uid: $0.objectID.uriRepresentation().absoluteString,
                                                 displayName: authorName,
                                                 authorNames: [authorName])
                }
                
                await self.spotlightHelper.index(authorAttributeSets)
                
                self.spotlightArticleIndexing.toggle()
            }
        }
        
        NotificationCenter.default
            .publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.fetchUpdates(notification)
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.defaultsChanged()
            }
            .store(in: &subscriptions)
        
        $articleSearchString
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { _ in
                self.searchArticle()
            }
            .store(in: &subscriptions)
        
        $authorSearchString
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { _ in
                self.searchAuthor()
            }
            .store(in: &subscriptions)
    }
    
    private func defaultsChanged() -> Void {
        logger.log("default changed")
        if !self.spotlightArticleIndexing {
            self.spotlightArticleIndexing.toggle()
        }
    }
    
    func parse(risString: String) async -> [RISRecord]? {
        let task = Task {
            let records = try await parser.parse(risString)
            return records
        }
        return try? await task.value
    }
    
    @Published var stringToExport: String = ""
    
    func export(collection: Collection, with order: ExportOrder = .dateEnd) async -> Void {
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
                if let ris = await parse(risString: risString), !ris.isEmpty {
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
    var allArticles = [Article]()
    @Published var authors = [Author]()
    @Published var allAuthors = [Author]()
    @Published var collections = [Collection]()
    @Published var allCollections = [Collection]()
    
    // read
    func fetchAll() {
        persistenceHelper.perform {
            self.logger.log("fetching articles")
            self.fetchArticles()
            self.logger.log("fetching authors")
            self.fetchAuthors()
            self.logger.log("fetching collections")
            self.fetchCollections()
            self.logger.log("fetching all articles")
            self.fetchAllArticles()
            self.logger.log("fetching all authors")
            self.fetchAllAuthors()
            self.logger.log("fetching all collections")
            self.fetchAllColections()
            self.logger.log("fetched all")
        }
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
        persistenceHelper.perform {
            self.save() { success in
                completionHandler?(success)
                self.articleSearchString = ""
                self.authorSearchString = ""
                self.fetchAll()
            }
        }
    }
    
    func save(completionHandler: ((Bool) -> Void)? = nil) -> Void {
        Task {
            do {
                try await persistenceHelper.save()
                completionHandler?(true)
            } catch {
                logger.log("Error while saving data: \(error.localizedDescription, privacy: .public)")
                showAlert.toggle()
                completionHandler?(false)
            }
        }
    }
    
    // create
    func save(risRecords: [RISRecord]) -> Void {
        persistenceHelper.performAndWait {
            let created = Date()
            risRecords.forEach {
                let article = self.createEntities(from: $0, created: created)
                self.addToIndex(article: article)
            }
            
        }
        
        saveAndFetch()
    }
    
    private func createEntities(from record: RISRecord, created at: Date) -> Article {
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
        
        // TODO: Add to index
        
        let ris = persistenceHelper.createRIS(from: record)
        ris.article = newArticle
        
        return newArticle
    }
    
    func add(contact: ContactDTO, to author: Author) -> Void {
        persistenceHelper.perform {
            let contactEntity = self.persistenceHelper.createAuthorContact(from: contact)
            author.addToContacts(contactEntity)
            self.save()
        }
    }
    
    func add(collection name: String, of articles: [Article]) -> Void {
        persistenceHelper.performAndWait {
            let collection = self.persistenceHelper.create(collection: name, of: articles)
            
            for index in 0..<articles.count {
                collection.addToArticles(articles[index])
                let _ = self.persistenceHelper.createOrder(in: collection, for: articles[index], with: Int64(index))
            }
        }
        
        saveAndFetch()
    }
    
    func add(article: Article, to collections: [Collection]) -> Void {
        persistenceHelper.performAndWait {
            collections.forEach { collection in
                let count = collection.articles == nil ? 0 : collection.articles!.count
                let _ = self.persistenceHelper.createOrder(in: collection, for: article, with: Int64(count))
                collection.addToArticles(article)
            }
        }
        
        saveAndFetch() { success in
            if !success {
                self.logger.log("AddToCollectionsView: Failed to update")
            }
        }
    }
    
    func add(references collections: [Collection], to article: Article) -> Void {
        persistenceHelper.performAndWait {
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
        }
        
        saveAndFetch() { success in
            if !success {
                self.logger.log("ImportCollectionAsReferencesView: Failed to update")
            }
        }
    }
    
    // delete
    private func delete(_ object: NSManagedObject) -> Void {
        persistenceHelper.delete(object)
    }
    
    func delete(_ articles: [Article]) -> Void {
        persistenceHelper.performAndWait {
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
        }
        
        saveAndFetch() { success in
            self.logger.log("Delete data: success=\(success)")
        }
    }
    
    func delete(_ authors: [Author]) -> Void {
        persistenceHelper.performAndWait {
            authors.forEach { author in
                if author.articles == nil || author.articles!.count == 0 {
                    self.deleteFromIndex(author: author)
                    self.delete(author)
                }
            }
        }
        
        saveAndFetch()
    }
    
    func delete(_ contacts: [AuthorContact], from author: Author) -> Void {
        persistenceHelper.performAndWait {
            contacts.forEach { contact in
                author.removeFromContacts(contact)
                self.delete(contact)
            }
        }
        
        saveAndFetch()
    }
    
    func delete(_ collections: [Collection]) -> Void {
        persistenceHelper.performAndWait {
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
        }
        
        saveAndFetch()
    }
    
    func delete(_ orders: [OrderInCollection], at offsets: IndexSet, in collection: Collection) -> Void {
        persistenceHelper.performAndWait {
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
        }
        
        saveAndFetch()
    }
    
    func rollback() -> Void {
        persistenceHelper.rollback()
    }
    
    // update
    func merge(authors: [Author]) -> Void {
        persistenceHelper.performAndWait {
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
                
                self.deleteFromIndex(author: authors[index])
                self.delete(authors[index])
            }
        }
        
        saveAndFetch()
    }
    
    func update(article: Article, with authors: [Author]) -> Void {
        persistenceHelper.performAndWait {
            self.logger.log("Updating article=\(article) with authors=\(authors)")
            article.authors?.forEach { author in
                if let author = author as? Author {
                    author.removeFromArticles(article)
                }
            }
            
            authors.forEach { author in
                author.addToArticles(article)
            }
        }

        saveAndFetch()
    }
    
    func update(collection: Collection, with articles: [Article]) -> Void {
        persistenceHelper.performAndWait {
            self.logger.log("Updating collection=\(collection) with articles=\(articles)")
            collection.orders?.forEach { order in
                if let order = order as? OrderInCollection {
                    self.delete(order)
                }
            }
            self.logger.log("Deleted orders")
            collection.articles?.forEach { article in
                if let article = article as? Article {
                    article.removeFromCollections(collection)
                }
            }
            self.logger.log("Removed articles")
            for index in 0..<articles.count {
                let article = articles[index]
                article.addToCollections(collection)
                
                let _ = self.persistenceHelper.createOrder(in: collection, for: article, with: Int64(index))
            }
            self.logger.log("Saving the update")
        }
        
        saveAndFetch()
    }
    
    func add(_ articles: [Article], to collections: [Collection]) -> Void {
        persistenceHelper.performAndWait {
            if !articles.isEmpty {
                collections.forEach { collection in
                    var count = collection.articles == nil ? 0 : collection.articles!.count
                    for article in articles {
                        let _ = self.persistenceHelper.createOrder(in: collection, for: article, with: Int64(count))
                        article.addToCollections(collection)
                        count += 1
                    }
                }
                self.save()
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
        
        let sortDescriptors = [NSSortDescriptor(key: "firstName", ascending: true)]
        let predicate = NSPredicate(format: "(lastName CONTAINS[cd] %@) AND (firstName BEGINSWITH[cd] %@)", argumentArray: [lastName, firstLetterOfFirstName.lowercased()])
        let fetchRequest = persistenceHelper.getFetchRequest(for: Author.self, entityName: "Author", sortDescriptors: sortDescriptors, predicate: predicate)
        return persistenceHelper.fetch(fetchRequest)
    }
    
    // MARK: - Persistence History Request
    private func fetchUpdates(_ notification: Notification) -> Void {
        Task {
            await persistence.fetchUpdates(notification) { result in
                switch result {
                case .success(let notification):
                    if let userInfo = notification.userInfo {
                        userInfo.forEach { key, value in
                            if let objectIDs = value as? Set<NSManagedObjectID> {
                                for objectId in objectIDs {
                                    Task {
                                        await self.addToIndex(objectId)
                                    }
                                }
                            }
                        }
                    }
                    break
                case .failure(let error):
                    self.logger.log("Error while persistence.fetchUpdates: \(error.localizedDescription, privacy: .public)")
                }
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
    private var articleSearchQuery: CSUserQuery?
    private var authorSearchQuery: CSUserQuery?
    @Published var articleSearchString = ""
    @Published var articleSuggestions: [String] = []
    @Published var authorSearchString = ""
    @Published var authorSuggestions: [String] = []
    
    private func toggleIndexing(_ indexer: NSCoreDataCoreSpotlightDelegate?, enabled: Bool) {
        guard let indexer = indexer else { return }
        if enabled {
            indexer.startSpotlightIndexing()
        } else {
            indexer.stopSpotlightIndexing()
        }
    }
    
    private func addToIndex(_ objectID: NSManagedObjectID) async -> Void {
        guard let object = persistenceHelper.find(with: objectID) else {
            await self.spotlightHelper.removeFromIndex(identifier: objectID.uriRepresentation().absoluteString)
            logger.log("Removed from index: \(objectID)")
            return
        }
        
        if let article = object as? Article {
            let articleAttributeSet = SpotlightAttributeSet(uid: article.objectID.uriRepresentation().absoluteString,
                                                            title: article.title,
                                                            textContent: article.abstract,
                                                            displayName: article.title,
                                                            contentDescription: article.journal)
            
            await self.spotlightHelper.index([articleAttributeSet])
        }
        
        if let author = object as? Author {
            let authorName = ToBeCitedNameFormatHelper.formatName(of: author)
            let authorAttributeSets = SpotlightAttributeSet(uid: author.objectID.uriRepresentation().absoluteString,
                                                            displayName: authorName,
                                                            authorNames: [authorName])
            await self.spotlightHelper.index([authorAttributeSets])
        }
    }
    
    private func addToIndex(article: Article) -> Void {
        Task {
            let articleAttributeSet = SpotlightAttributeSet(uid: article.objectID.uriRepresentation().absoluteString,
                                                            title: article.title,
                                                            textContent: article.abstract,
                                                            displayName: article.title,
                                                            contentDescription: article.journal)
            
            await self.spotlightHelper.index([articleAttributeSet])
            
            if let authors = article.authors {
                let authorAttributeSets = authors.compactMap { author in
                    if let author = author as? Author {
                        let authorName = ToBeCitedNameFormatHelper.formatName(of: author)
                        return SpotlightAttributeSet(uid: author.objectID.uriRepresentation().absoluteString,
                                                     displayName: authorName,
                                                     authorNames: [authorName])
                    } else {
                        return nil
                    }
                }
                
                await self.spotlightHelper.index(authorAttributeSets)
            }
        }
    }
    
    private func deleteFromIndex(article: Article) -> Void {
        logger.log("Remove \(article, privacy: .public) from the index")
        Task {
            await self.spotlightHelper.deleteFromIndex(article: article)
        }
        
    }
    
    private func deleteFromIndex(author: Author) -> Void {
        logger.log("Remove \(author, privacy: .public) from the index")
        Task {
            await self.spotlightHelper.deleteFromIndex(author: author)
        }
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
        let queryContext = CSUserQueryContext()
        queryContext.fetchAttributes = ["title", "textContent"]
        queryContext.maxSuggestionCount = 10
        
        articleSearchQuery = CSUserQuery(queryString: queryString, queryContext: queryContext)
        
        guard let articleSearchQuery = articleSearchQuery else {
            logger.log("articleSearchQuery is null")
            return
        }
        
        logger.log("searchArticles: \(queryString, privacy: .public)")
        
        Task {
            do {
                for try await item in articleSearchQuery.responses {
                    switch item {
                    case .item(let item):
                        self.spotlightFoundArticles += [item.item]
                    case .suggestion(let suggestion):
                        self.articleSuggestions += [String(suggestion.suggestion.localizedAttributedSuggestion.characters)]
                    @unknown default:
                        break
                    }
                }
                
                self.fetchArticles(self.spotlightFoundArticles)
                self.spotlightFoundArticles.removeAll()
            } catch {
                self.logger.log("Searching \(self.articleSearchString) came back with error: \(error.localizedDescription, privacy: .public)")
            }
        }
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
        let queryString = "(authorNames == \"*\(escapedText)*\"cd)"
        let queryContext = CSUserQueryContext()
        queryContext.fetchAttributes = ["authorNames", "displayName"]
        queryContext.maxSuggestionCount = 10
        
        authorSearchQuery = CSUserQuery(queryString: queryString, queryContext: queryContext)
        
        guard let authorSearchQuery = authorSearchQuery else {
            logger.log("authorSearchQuery is null")
            return
        }
        
        logger.log("searchAuthors: \(queryString, privacy: .public)")
        
        Task {
            do {
                for try await item in authorSearchQuery.responses {
                    switch item {
                    case .item(let item):
                        self.spotlightFoundAuthors += [item.item]
                    case .suggestion(let suggestion):
                        self.authorSuggestions += [String(suggestion.suggestion.localizedAttributedSuggestion.characters)]
                    @unknown default:
                        break
                    }
                }
                
                self.fetchAuthors(self.spotlightFoundAuthors)
                self.spotlightFoundAuthors.removeAll()
            } catch {
                self.logger.log("Searching \(self.authorSearchString) came back with error: \(error.localizedDescription, privacy: .public)")
            }
        }
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
    
    public func stopIndexing() {
        Task {
            await spotlightHelper.stopIndexing()
        }
    }
    
    public func startIndexing() {
        Task {
            await spotlightHelper.startIndexing()
        }
    }
    
    // TODO:
    @available(*, renamed: "continueActivity(_:)")
    func continueActivity(_ activity: NSUserActivity, completionHandler: @escaping (NSManagedObject?) -> Void) {
        Task {
            let result = await continueActivity(activity)
            completionHandler(result)
        }
    }
    
    func continueActivity(_ activity: NSUserActivity) async -> NSManagedObject? {
        logger.log("continueActivity: \(activity)")
        guard let info = activity.userInfo, let objectIdentifier = info[CSSearchableItemActivityIdentifier] as? String else {
            return nil
        }
        
        guard let objectURI = URL(string: objectIdentifier), let entity = persistenceHelper.find(for: objectURI) else {
            logger.log("Can't find an object with objectIdentifier=\(objectIdentifier)")
            return nil
        }
        
        logger.log("entity = \(entity)")
        
        return await withCheckedContinuation { continuation in
            if let article = entity as? Article {
                self.selectedTab = .articles
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    continuation.resume(returning: article)
                }
            } else if let author = entity as? Author {
                self.selectedTab = .authors
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    continuation.resume(returning: author)
                }
            }
        }
    }
    
}
