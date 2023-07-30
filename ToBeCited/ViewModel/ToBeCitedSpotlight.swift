//
//  ToBeCitedSpotlight.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 7/30/23.
//

import Foundation
import CoreSpotlight
import CoreData

class ArticleSpotlightDelegate: NSCoreDataCoreSpotlightDelegate {
    override func domainIdentifier() -> String {
        return ToBeCitedConstants.domainIdentifier.rawValue
    }

    override func indexName() -> String? {
        return ToBeCitedConstants.articleIndexName.rawValue
    }
    
    override func attributeSet(for object: NSManagedObject) -> CSSearchableItemAttributeSet? {
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
}
