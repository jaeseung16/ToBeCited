//
//  RISParser.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/18/21.
//

import Foundation

actor RISParser {
    private var dict = [RISTag: String]()
    private var authors = [String]()
    private var keywords = [String]()
    private var relatedRecords = [String]()
    private var images = [String]()
    
    init() {
    }
    
    private let pattern = "^([a-zA-Z|\\d]{2})  - (.+)"
    
    func parse(_ risString: String) throws -> [RISRecord] {
        let re = try NSRegularExpression(pattern: pattern)
        var records = [RISRecord]()
        
        risString.enumerateLines { [self] stringToMatch, _ in
            if stringToMatch.starts(with: RISTag.ER.rawValue) {
                let record = self.buildRecord()
                records.append(record)
                self.reset()
            } else {
                let matches = re.matches(in: stringToMatch, options: .anchored, range: NSMakeRange(0, stringToMatch.count))
                for match in matches {
                    let tag = (stringToMatch as NSString).substring(with: match.range(at: 1))
                    let value = (stringToMatch as NSString).substring(with: match.range(at: 2))
                    if let risTag = RISTag(rawValue: tag) {
                        switch risTag {
                        case .AU:
                            self.authors.append(value)
                        case .KW:
                            self.keywords.append(value)
                        case .L3:
                            self.relatedRecords.append(value)
                        case .L4:
                            self.images.append(value)
                        default:
                            self.dict[risTag] = value
                        }
                    }
                }
            }
        }
        
        return records
    }
    
    private func reset() -> Void {
        dict.removeAll()
        authors.removeAll()
        keywords.removeAll()
        relatedRecords.removeAll()
        images.removeAll()
    }
    
    private func buildRecord() -> RISRecord {
        let referenceType = dict[.TY]?.uppercased() ?? "JOUR"
        return RISRecord(referenceType: RISReferenceType(rawValue: referenceType) ?? .JOUR,
                         primaryAuthor: dict[.A1],
                         secondaryAuthor: dict[.A2],
                         tertiaryAuthor: dict[.A3],
                         subsidiaryAuthor: dict[.A4],
                         abstract: dict[.AB],
                         authorAddress: dict[.AD],
                         accessionNumber: dict[.AN],
                         authors: authors,
                         archiveLocation: dict[.AV],
                         bookTitle: dict[.BT],
                         custom1: dict[.C1],
                         custom2: dict[.C2],
                         custom3: dict[.C3],
                         custom4: dict[.C4],
                         custom5: dict[.C5],
                         custom6: dict[.C6],
                         custom7: dict[.C7],
                         custom8: dict[.C8],
                         caption: dict[.CA],
                         callNumber: dict[.CN],
                         cp: dict[.CP],
                         titleOfUnpublishedReference: dict[.CT],
                         placePublished: dict[.CY],
                         date: dict[.DA],
                         databaseName: dict[.DB],
                         doi: dict[.DO],
                         databaseProvider: dict[.DP],
                         editor: dict[.ED],
                         endPage: dict[.EP],
                         edition: dict[.ET],
                         referenceID: dict[.ID],
                         issueNumber: dict[.IS],
                         periodicalNameUserAbbreviation: dict[.J1],
                         alternateTitle: dict[.J2],
                         periodicalNameStandAbbreviation: dict[.JA],
                         periodicalNameFullFormat: dict[.JF] ?? dict[.JO],
                         keywords: keywords,
                         linkToPDF: dict[.L1],
                         linkToFullText: dict[.L2],
                         relatedRecords: relatedRecords,
                         images: images,
                         language: dict[.LA],
                         label: dict[.LB],
                         webLink: dict[.LK],
                         miscellaneous1: dict[.M1],
                         miscellaneous2: dict[.M2],
                         miscellaneous3: dict[.M3],
                         notes1: dict[.N1],
                         notes2: dict[.N2],
                         numberOfVolumes: dict[.NV],
                         originalPublication: dict[.OP],
                         publisher: dict[.PB],
                         publishingPlace: dict[.PP],
                         pulbicationYear: dict[.PY],
                         reviewedItem: dict[.RI],
                         reseatchNotes: dict[.RN],
                         reprintEdition: dict[.RP],
                         section: dict[.SE],
                         isbn: dict[.SN],
                         startPage: dict[.SP],
                         shortTitle: dict[.ST],
                         primaryTitle: dict[.T1],
                         secondaryTitle: dict[.T2],
                         tertiaryTitle: dict[.T3],
                         translatedAuthor: dict[.TA],
                         title: dict[.TI],
                         translatedTitle: dict[.TT],
                         userDefinable1: dict[.U1],
                         userDefinable2: dict[.U2],
                         userDefinable3: dict[.U3],
                         userDefinable4: dict[.U4],
                         userDefinable5: dict[.U5],
                         url: dict[.UR],
                         volumeNumber: dict[.VL],
                         publishedStandardNumber: dict[.VO],
                         primaryDate: dict[.Y1],
                         accessDate: dict[.Y2])

    }
}

