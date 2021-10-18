//
//  RISWriter.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/18/21.
//

import Foundation

class RISWriter {
    private let record: RISRecord
    
    init(record: RISRecord) {
        self.record = record
    }
    
    func toString() -> String {
        var result = "TY  - \(record.referenceType.rawValue)\n"
        
        if let primaryAuthor = record.primaryAuthor {
            result.append(contentsOf: "A1  - \(primaryAuthor)\n")
        }
        
        if let secondaryAuthor = record.secondaryAuthor {
            result.append(contentsOf: "A2  - \(secondaryAuthor)\n")
        }
        
        if let tertiaryAuthor = record.tertiaryAuthor {
            result.append(contentsOf: "A3  - \(tertiaryAuthor)\n")
        }
        
        if let subsidiaryAuthor = record.subsidiaryAuthor {
            result.append(contentsOf: "A4  - \(subsidiaryAuthor)\n")
        }
        
        if let abstract = record.abstract {
            result.append(contentsOf: "AB  - \(abstract)\n")
        }
        
        if let authorAddress = record.authorAddress {
            result.append(contentsOf: "AD  - \(authorAddress)\n")
        }
           
        if let accessionNumber = record.accessionNumber {
            result.append(contentsOf: "AN  - \(accessionNumber)\n")
        }
           
        record.authors.forEach { author in
            result.append(contentsOf: "AU  - \(author)\n")
        }
        
        if let archiveLocation = record.archiveLocation {
            result.append(contentsOf: "AV  - \(archiveLocation)\n")
        }
        
        if let bookTitle = record.bookTitle {
            result.append(contentsOf: "BT  - \(bookTitle)\n")
        }
      
        if let custom1 = record.custom1 {
            result.append(contentsOf: "C1  - \(custom1)\n")
        }
        
        if let custom2 = record.custom2 {
            result.append(contentsOf: "C2  - \(custom2)\n")
        }
        
        if let custom3 = record.custom3 {
            result.append(contentsOf: "C3  - \(custom3)\n")
        }
        
        if let custom4 = record.custom4 {
            result.append(contentsOf: "C4  - \(custom4)\n")
        }
        
        if let custom5 = record.custom5 {
            result.append(contentsOf: "C5  - \(custom5)\n")
        }
        
        if let custom6 = record.custom6 {
            result.append(contentsOf: "C6  - \(custom6)\n")
        }
        
        if let custom7 = record.custom7 {
            result.append(contentsOf: "C7  - \(custom7)\n")
        }
        
        if let custom8 = record.custom8 {
            result.append(contentsOf: "C8  - \(custom8)\n")
        }
        
        if let caption = record.caption {
            result.append(contentsOf: "CA  - \(caption)\n")
        }
        
        if let callNumber = record.callNumber {
            result.append(contentsOf: "CN  - \(callNumber)\n")
        }
          
        if let cp = record.cp {
            result.append(contentsOf: "CP  - \(cp)\n")
        }
        
        if let titleOfUnpublishedReference = record.titleOfUnpublishedReference {
            result.append(contentsOf: "CT  - \(titleOfUnpublishedReference)\n")
        }
        
        if let placePublished = record.placePublished {
            result.append(contentsOf: "CY  - \(placePublished)\n")
        }
        
        if let date = record.date {
            result.append(contentsOf: "DA  - \(date)\n")
        }
        
        if let databaseName = record.databaseName {
            result.append(contentsOf: "DB  - \(databaseName)\n")
        }
        
        if let doi = record.doi {
            result.append(contentsOf: "DO  - \(doi)\n")
        }
        
        if let databaseProvider = record.databaseProvider {
            result.append(contentsOf: "DP  - \(databaseProvider)\n")
        }
        
        if let editor = record.editor {
            result.append(contentsOf: "ED  - \(editor)\n")
        }
          
        if let endPage = record.endPage {
            result.append(contentsOf: "EP  - \(endPage)\n")
        }
        
        if let edition = record.edition {
            result.append(contentsOf: "ET  - \(edition)\n")
        }
        
        if let referenceID = record.referenceID {
            result.append(contentsOf: "ID  - \(referenceID)\n")
        }
        
        if let issueNumber = record.issueNumber {
            result.append(contentsOf: "IS  - \(issueNumber)\n")
        }
        
        if let periodicalNameUserAbbreviation = record.periodicalNameUserAbbreviation {
            result.append(contentsOf: "J1  - \(periodicalNameUserAbbreviation)\n")
        }
        
        if let alternateTitle = record.alternateTitle {
            result.append(contentsOf: "J2  - \(alternateTitle)\n")
        }
        
        if let periodicalNameStandAbbreviation = record.periodicalNameStandAbbreviation {
            result.append(contentsOf: "JA  - \(periodicalNameStandAbbreviation)\n")
        }
             
        if let periodicalNameFullFormat = record.periodicalNameFullFormat {
            result.append(contentsOf: "JF  - \(periodicalNameFullFormat)\n")
            result.append(contentsOf: "JO  - \(periodicalNameFullFormat)\n")
        }
                
        record.keywords.forEach { keyworkd in
            result.append(contentsOf: "KW  - \(keyworkd)\n")
        }
        
        if let linkToPDF = record.linkToPDF {
            result.append(contentsOf: "L1  - \(linkToPDF)\n")
        }
        
        if let linkToFullText = record.linkToFullText {
            result.append(contentsOf: "L2  - \(linkToFullText)\n")
        }
                               
        record.relatedRecords.forEach { relatedRecord in
            result.append(contentsOf: "L3  - \(relatedRecord)\n")
        }
        
        record.images.forEach { image in
            result.append(contentsOf: "L4  - \(image)\n")
        }
           
        if let language = record.language {
            result.append(contentsOf: "LA  - \(language)\n")
        }
        
        if let label = record.label {
            result.append(contentsOf: "LB  - \(label)\n")
        }
        
        if let webLink = record.webLink {
            result.append(contentsOf: "LK  - \(webLink)\n")
        }
        
        if let miscellaneous1 = record.miscellaneous1 {
            result.append(contentsOf: "M1  - \(miscellaneous1)\n")
        }
        
        if let miscellaneous2 = record.miscellaneous2 {
            result.append(contentsOf: "M2  - \(miscellaneous2)\n")
        }
        
        if let miscellaneous3 = record.miscellaneous3 {
            result.append(contentsOf: "M3  - \(miscellaneous3)\n")
        }
        
        if let notes1 = record.notes1 {
            result.append(contentsOf: "N1  - \(notes1)\n")
        }
        
        if let notes2 = record.notes2 {
            result.append(contentsOf: "N2  - \(notes2)\n")
        }
        
        if let numberOfVolumes = record.numberOfVolumes {
            result.append(contentsOf: "NV  - \(numberOfVolumes)\n")
        }
        
        if let originalPublication = record.originalPublication {
            result.append(contentsOf: "OP  - \(originalPublication)\n")
        }
        
        if let publisher = record.publisher {
            result.append(contentsOf: "PB  - \(publisher)\n")
        }
              
        if let publishingPlace = record.publishingPlace {
            result.append(contentsOf: "PP  - \(publishingPlace)\n")
        }
        
        if let pulbicationYear = record.pulbicationYear {
            result.append(contentsOf: "PY  - \(pulbicationYear)\n")
        }
        
        if let reviewedItem = record.reviewedItem {
            result.append(contentsOf: "RI  - \(reviewedItem)\n")
        }
        
        if let reseatchNotes = record.reseatchNotes {
            result.append(contentsOf: "RN  - \(reseatchNotes)\n")
        }
        
        if let reprintEdition = record.reprintEdition {
            result.append(contentsOf: "RP  - \(reprintEdition)\n")
        }
        
        if let section = record.section {
            result.append(contentsOf: "SE  - \(section)\n")
        }
        
        if let isbn = record.isbn {
            result.append(contentsOf: "SN  - \(isbn)\n")
        }
        
        if let startPage = record.startPage {
            result.append(contentsOf: "SP  - \(startPage)\n")
        }
        
        if let shortTitle = record.shortTitle {
            result.append(contentsOf: "ST  - \(shortTitle)\n")
        }
            
        if let primaryTitle = record.primaryTitle {
            result.append(contentsOf: "T1  - \(primaryTitle)\n")
        }
        
        if let secondaryTitle = record.secondaryTitle {
            result.append(contentsOf: "T2  - \(secondaryTitle)\n")
        }
        
        if let tertiaryTitle = record.tertiaryTitle {
            result.append(contentsOf: "T3  - \(tertiaryTitle)\n")
        }
        
        if let translatedAuthor = record.translatedAuthor {
            result.append(contentsOf: "TA  - \(translatedAuthor)\n")
        }
        
        if let title = record.title {
            result.append(contentsOf: "TI  - \(title)\n")
        }
        
        if let userDefinable1 = record.userDefinable1 {
            result.append(contentsOf: "U1  - \(userDefinable1)\n")
        }
        
        if let userDefinable2 = record.userDefinable2 {
            result.append(contentsOf: "U2  - \(userDefinable2)\n")
        }
        
        if let userDefinable3 = record.userDefinable3 {
            result.append(contentsOf: "U3  - \(userDefinable3)\n")
        }
        
        if let userDefinable4 = record.userDefinable4 {
            result.append(contentsOf: "U4  - \(userDefinable4)\n")
        }
        
        if let userDefinable5 = record.userDefinable5 {
            result.append(contentsOf: "U5  - \(userDefinable5)\n")
        }
        
        if let url = record.url {
            result.append(contentsOf: "UR  - \(url)\n")
        }
        
        if let volumeNumber = record.volumeNumber {
            result.append(contentsOf: "VL  - \(volumeNumber)\n")
        }
        
        if let publishedStandardNumber = record.publishedStandardNumber {
            result.append(contentsOf: "VO  - \(publishedStandardNumber)\n")
        }
              
        if let primaryDate = record.primaryDate {
            result.append(contentsOf: "Y1  - \(primaryDate)\n")
        }
        
        if let accessDate = record.accessDate {
            result.append(contentsOf: "Y2  - \(accessDate)\n")
        }
        
        result.append("ER  - \n")
        return result
    }
    
}
