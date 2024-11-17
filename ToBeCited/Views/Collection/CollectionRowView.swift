//
//  CollectionRowView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/17/24.
//

import SwiftUI

struct CollectionRowView: View {
    
    @ObservedObject var collection: Collection
    private var articleCount: Int {
        collection.articles?.count ?? 0
    }
    
    var body: some View {
        HStack {
            Text(collection.name ?? "")
            Spacer()
            Label("\(articleCount)", systemImage: "doc.on.doc")
                .font(.callout)
                .foregroundColor(Color.secondary)
        }
    }
}
