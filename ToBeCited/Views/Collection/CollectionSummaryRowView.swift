//
//  CollectionSummaryRowView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/5/24.
//

import SwiftUI

struct CollectionSummaryRowView: View {
    
    @State var collection: Collection
    
    var body: some View {
        HStack {
            Text(collection.name ?? "No title")
            Spacer()
            Text(collection.created ?? Date(), style: .date)
                .font(.callout)
                .foregroundColor(.secondary)
        }
    }
}
