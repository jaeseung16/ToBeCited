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

class ToBeCitedViewModel: NSObject, ObservableObject {
    static let shared = ToBeCitedViewModel()
    let logger = Logger()
    
    private let persistenteContainer = PersistenceController.shared.container
    private let parser = RISParser()
    
    @Published var ordersInCollection = [OrderInCollection]()
    @Published var toggle = false
    @Published var showAlert = false
    
    var collection: Collection?
    var articlesInCollection: [Article]?
    
    private var subscriptions: Set<AnyCancellable> = []
    
    var yearOnlyDateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        return dateFormatter
    }
    
    override init() {
        super.init()
        
        NotificationCenter.default
          .publisher(for: .NSPersistentStoreRemoteChange)
          .sink { self.fetchUpdates($0) }
          .store(in: &subscriptions)
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
    func save(viewContext: NSManagedObjectContext) -> Void {
        do {
            try viewContext.save()
        } catch {
            viewContext.rollback()
            let nsError = error as NSError
            logger.error("While saving data, occured an unresolved error \(nsError), \(nsError.userInfo)")
            showAlert.toggle()
        }
        
        toggle.toggle()
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
        
        save(viewContext: viewContext)
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
            
            self.save(viewContext: viewContext)
        }
    }
    
    // MARK: - Persistence History Request
    private lazy var historyRequestQueue = DispatchQueue(label: "history")
    private func fetchUpdates(_ notification: Notification) -> Void {
        //print("fetchUpdates \(Date().description(with: Locale.current))")
        historyRequestQueue.async {
            let backgroundContext = self.persistenteContainer.newBackgroundContext()
            backgroundContext.performAndWait {
                do {
                    let fetchHistoryRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: self.lastToken)
                    
                    if let historyResult = try backgroundContext.execute(fetchHistoryRequest) as? NSPersistentHistoryResult,
                       let history = historyResult.result as? [NSPersistentHistoryTransaction] {
                        for transaction in history.reversed() {
                            self.persistenteContainer.viewContext.perform {
                                if let userInfo = transaction.objectIDNotification().userInfo {
                                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: userInfo,
                                                                        into: [self.persistenteContainer.viewContext])
                                }
                            }
                        }
                        
                        self.lastToken = history.last?.token
                        
                        DispatchQueue.main.async {
                            self.toggle.toggle()
                        }
                    }
                } catch {
                    self.logger.error("Could not convert history result to transactions after lastToken = \(String(describing: self.lastToken)): \(error.localizedDescription)")
                }
                //print("fetchUpdates \(Date().description(with: Locale.current))")
            }
        }
    }
    
    private var lastToken: NSPersistentHistoryToken? = nil {
        didSet {
            guard let token = lastToken,
                  let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else {
                return
            }
            
            do {
                try data.write(to: tokenFile)
            } catch {
                let message = "Could not write token data"
                logger.error("###\(#function): \(message): \(error.localizedDescription)")
            }
        }
    }
    
    private lazy var tokenFile: URL = {
        let url = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("ToBeCited",isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url,
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
            } catch {
                let message = "Could not create persistent container URL"
                logger.error("###\(#function): \(message): \(error.localizedDescription)")
            }
        }
        return url.appendingPathComponent("token.data", isDirectory: false)
    }()

}
