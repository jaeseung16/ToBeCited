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
    
    func save(viewContext: NSManagedObjectContext) -> Void {
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        toggle.toggle()
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
    
    func populate(author: Author, with components: PersonNameComponents) {
        author.lastName = components.familyName
        author.firstName = components.givenName
        author.middleName = components.middleName
        author.nameSuffix = components.nameSuffix
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
