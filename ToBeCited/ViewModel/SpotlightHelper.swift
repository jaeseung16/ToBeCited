//
//  SpotlightHelper.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/19/24.
//

import Foundation
import CoreSpotlight
import os
@preconcurrency import CoreData

actor SpotlightHelper {
    let logger = Logger()
    
    private let persistenceHelper: PersistenceHelper
    private let articleIndexer: ArticleSpotlightDelegate?
    
    init(persistenceHelper: PersistenceHelper) {
        self.persistenceHelper = persistenceHelper
        
        if let articleIndexer: ArticleSpotlightDelegate = persistenceHelper.getSpotlightDelegate() as? ArticleSpotlightDelegate {
            self.articleIndexer = articleIndexer
        } else {
            self.articleIndexer = nil
        }
        
        Task {
            await self.startIndexing()
        }
    }
    
    public func startIndexing() {
        if let indexer = articleIndexer {
            indexer.startSpotlightIndexing()
        }
    }
    
    public func stopIndexing() {
        if let indexer = articleIndexer {
            indexer.stopSpotlightIndexing()
        }
    }
    
    public func index(_ attributeSets: [SpotlightAttributeSet]) {
        guard let indexName = articleIndexer?.indexName() as? String else {
            self.logger.log("Cannot get index name for \(self.articleIndexer, privacy: .public)")
            return
        }
        
        let searchableItems: [CSSearchableItem] = attributeSets.compactMap {
            CSSearchableItem(uniqueIdentifier: $0.uid, domainIdentifier: ToBeCitedConstants.domainIdentifier.rawValue, attributeSet: $0.getAttributeSet())
        }
        
        logger.log("Adding \(searchableItems.count) items to index=\(indexName, privacy: .public)")
        
        CSSearchableIndex(name: indexName).indexSearchableItems(searchableItems) { error in
            guard let error = error else {
                return
            }
            self.logger.log("Error while indexing: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    public func removeAuthorsFromIndex() async {
        do {
            try await CSSearchableIndex(name: ToBeCitedConstants.authorIndexName.rawValue).deleteAllSearchableItems()
        } catch {
            logger.log("Error while removing articles from index: \(error)")
        }
    }
    
    public func deleteFromIndex(article: Article) -> Void {
        logger.log("Remove \(article, privacy: .public) from the index")
        remove<Article>(article)
    }
    
    public func deleteFromIndex(author: Author) -> Void {
        logger.log("Remove \(author, privacy: .public) from the index")
        remove<Author>(author)
    }
    
    private func remove<T: NSManagedObject>(_ entity: T) -> Void {
        guard let indexName = articleIndexer?.indexName() as? String else {
            self.logger.log("Cannot get index name for \(self.articleIndexer, privacy: .public)")
            return
        }
        
        let identifier = entity.objectID.uriRepresentation().absoluteString
        
        CSSearchableIndex(name: indexName).deleteSearchableItems(withIdentifiers: [identifier]) { error in
            self.logger.log("Can't delete an item with identifier=\(identifier, privacy: .public)")
        }
    }
    
}
