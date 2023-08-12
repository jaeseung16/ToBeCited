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
