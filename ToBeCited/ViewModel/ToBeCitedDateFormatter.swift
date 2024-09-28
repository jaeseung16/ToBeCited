//
//  ToBeCitedDateFormatter.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 8/5/23.
//

import Foundation

enum ToBeCitedDateFormatter {
    
    case publication, collection, yearOnly, authorContact
    
    private func dateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        switch self {
        case .publication, .authorContact:
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
        case .collection:
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .medium
        case .yearOnly:
            dateFormatter.dateFormat = "yyyy"
        }
        return dateFormatter
    }
    
    func string(from date: Date) -> String {
        return dateFormatter().string(from: date)
    }
    
    func date(from date: String) -> Date? {
        return dateFormatter().date(from: date)
    }
}
