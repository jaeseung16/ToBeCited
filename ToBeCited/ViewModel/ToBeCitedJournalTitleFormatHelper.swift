//
//  ToBeCitedJournalTitleFormatter.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 8/13/23.
//

import Foundation

class ToBeCitedJournalTitleFormatHelper {
    
    class func journalTitle(of article: Article) -> String {
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
}
