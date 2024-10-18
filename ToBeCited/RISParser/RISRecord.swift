//
//  RISRecord.swift
//  
//
//  Created by Jae Seung Lee on 10/17/21.
//

import Foundation

public struct RISRecord: CustomStringConvertible, Sendable {
    var referenceType: RISReferenceType
    var primaryAuthor: String?
    var secondaryAuthor: String?
    var tertiaryAuthor: String?
    var subsidiaryAuthor: String?
    var abstract: String?
    var authorAddress: String?
    var accessionNumber: String?
    var authors: [String]
    var archiveLocation: String?
    var bookTitle: String?
    var custom1: String?
    var custom2: String?
    var custom3: String?
    var custom4: String?
    var custom5: String?
    var custom6: String?
    var custom7: String?
    var custom8: String?
    var caption: String?
    var callNumber: String?
    var cp: String?
    var titleOfUnpublishedReference: String?
    var placePublished: String?
    var date: String?
    var databaseName: String?
    var doi: String?
    var databaseProvider: String?
    var editor: String?
    var endPage: String?
    var edition: String?
    var referenceID: String?
    var issueNumber: String?
    var periodicalNameUserAbbreviation: String?
    var alternateTitle: String?
    var periodicalNameStandAbbreviation: String?
    var periodicalNameFullFormat: String?
    var keywords: [String]
    var linkToPDF: String?
    var linkToFullText: String?
    var relatedRecords: [String]
    var images: [String]
    var language: String?
    var label: String?
    var webLink: String?
    var miscellaneous1: String?
    var miscellaneous2: String?
    var miscellaneous3: String?
    var notes1: String?
    var notes2: String?
    var numberOfVolumes: String?
    var originalPublication: String?
    var publisher: String?
    var publishingPlace: String?
    var pulbicationYear: String?
    var reviewedItem: String?
    var reseatchNotes: String?
    var reprintEdition: String?
    var section: String?
    var isbn: String?
    var startPage: String?
    var shortTitle: String?
    var primaryTitle: String?
    var secondaryTitle: String?
    var tertiaryTitle: String?
    var translatedAuthor: String?
    var title: String?
    var translatedTitle: String?
    var userDefinable1: String?
    var userDefinable2: String?
    var userDefinable3: String?
    var userDefinable4: String?
    var userDefinable5: String?
    var url: String?
    var volumeNumber: String?
    var publishedStandardNumber: String?
    var primaryDate: String?
    var accessDate: String?
    
    public var description: String {
        authorsDescription
        + titleDescription
        + journalDescription
        + volumnIssuePagesDescription
        + dateDescription
        + doiDescription
    }
    
    public var dateFirstDescription: String {
        authorsDescription
        + dateDescription
        + titleDescription
        + journalDescription
        + volumnIssuePagesDescription
        + doiDescription
    }
    
    public var dateMiddleDescription: String {
        authorsDescription
        + titleDescription
        + journalDescription
        + dateDescription
        + volumnIssuePagesDescription
        + doiDescription
    }
    
    private var authorsDescription: String {
        var description = ""
        
        if let primaryAuthor = primaryAuthor {
            description += "\(primaryAuthor);"
        }
        
        if let secondaryAuthor = secondaryAuthor {
            description += "\(secondaryAuthor);"
        }
        
        if let tertiaryAuthor = tertiaryAuthor {
            description += "\(tertiaryAuthor);"
        }
        
        if let subsidiaryAuthor = subsidiaryAuthor {
            description += "\(subsidiaryAuthor);"
        }
        
        authors.forEach { description += "\($0);" }
        
        return description
    }
    
    private var titleDescription: String {
        var description = ""
        if let primaryTitle = primaryTitle {
            description += "\(primaryTitle);"
        } else if let title = title {
            description += "\(title);"
        }
        return description
    }
    
    private var journalDescription: String {
        var description = ""
        if let periodicalNameFullFormat = periodicalNameFullFormat {
            description += "\(periodicalNameFullFormat);"
        }
        return description
    }
    
    private var volumnIssuePagesDescription: String {
        var description = ""
        
        if let volumeNumber = volumeNumber {
            description += "\(volumeNumber);"
        }
        
        if let issueNumber = issueNumber {
            description += "(\(issueNumber));"
        }
        
        if let startPage = startPage {
            description += "\(startPage);"
        }
        
        if let endPage = endPage {
            description += "\(endPage);"
        }
        
        return description
    }
    
    private var dateDescription: String {
        var description = ""
        if let pulbicationYear = pulbicationYear {
            description += "(\(pulbicationYear));"
        } else if let date = date {
            description += "(\(date));"
        } else if let primaryDate = primaryDate {
            description += "(\(primaryDate));"
        }
        return description
    }
    
    private var doiDescription: String {
        var description = ""
        if let doi = doi {
            description += "doi: \(doi);"
        }
        return description
    }
}
