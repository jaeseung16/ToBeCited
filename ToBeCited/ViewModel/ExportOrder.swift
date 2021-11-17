//
//  ExportOrder.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/17/21.
//

import Foundation

enum ExportOrder: String, CaseIterable, Identifiable, CustomStringConvertible {
    case dateFirst // Date, Title, Journal, Volume, Issue, Pages
    case dateMiddle // Title, Journal, Date, Volume, Issue, Pages
    case dateEnd // Title, Journal, Volume, Issue, Pages, Date
    
    var id: String {
        self.rawValue
    }
    
    public var description: String {
        switch self {
        case .dateFirst:
            return "<date><title:journal><volume:issue:pages>"
        case .dateMiddle:
            return "<title:journal><date><volume:issue:pages>"
        case .dateEnd:
            return "<title:journal><volume:issue:pages><date>"
        }
    }
}

enum ExportField {
    case title
    case journal
    case volumn
    case issue
    case pages
    case date
}
