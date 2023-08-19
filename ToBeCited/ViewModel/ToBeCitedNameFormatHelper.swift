//
//  ToBeCitedNameFormatter.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 8/12/23.
//

import Foundation

class ToBeCitedNameFormatHelper {
    class func nameComponents(of author: Author) -> PersonNameComponents {
        return PersonNameComponents(givenName: author.firstName,
                                    middleName: author.middleName,
                                    familyName: author.lastName,
                                    nameSuffix: author.nameSuffix)
    }
    
    class func format(style: PersonNameComponents.FormatStyle.Style) -> PersonNameComponents.FormatStyle {
        return PersonNameComponents.FormatStyle.name(style: style)
    }
    
    class func formatName(of author: Author) -> String {
        format(style: .long).format(nameComponents(of: author))
    }
}

extension Author: Comparable {
    public static func < (lhs: Author, rhs: Author) -> Bool {
        if let lastName1 = lhs.lastName, let lastName2 = rhs.lastName {
            if lastName1 == lastName2 {
                if let firstName1 = lhs.firstName, let firstName2 = rhs.firstName {
                    return firstName1 < firstName2
                } else if let _ = lhs.firstName {
                    return true
                } else {
                    return false
                }
            } else {
                return lastName1 < lastName2
            }
        } else if let _ = lhs.lastName {
            return true
        }
        return false
    }
    
    public static func == (lhs: Author, rhs: Author) -> Bool {
        if let lastName1 = lhs.lastName, let lastName2 = rhs.lastName {
            if lastName1 == lastName2 {
                if lhs.firstName == nil && rhs.firstName == nil {
                    return true
                } else if let firstName1 = lhs.firstName, let firstName2 = rhs.firstName {
                    return firstName1 == firstName2
                } else  {
                    return false
                }
            }
        }
        return false
    }
}
