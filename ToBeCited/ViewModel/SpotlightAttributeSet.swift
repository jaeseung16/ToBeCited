//
//  SpotlightAttributeSet.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/19/24.
//

import CoreSpotlight

struct SpotlightAttributeSet: Sendable {
    
    let uid: String
    let contentType = UTType.text
    let title: String?
    let textContent: String?
    let displayName: String?
    let contentDescription: String?
    let isUpdated: Bool
    
    init(uid: String, title: String? = nil, textContent: String? = nil, displayName: String? = nil, contentDescription: String? = nil, isUpdated: Bool = false) {
        self.uid = uid
        self.title = title
        self.textContent = textContent
        self.displayName = displayName
        self.contentDescription = contentDescription
        self.isUpdated = isUpdated
    }
    
    func getAttributeSet() -> CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(contentType: contentType)
        attributeSet.title = title
        attributeSet.textContent = textContent
        attributeSet.displayName = displayName
        attributeSet.contentDescription = contentDescription
        return attributeSet
    }
}
