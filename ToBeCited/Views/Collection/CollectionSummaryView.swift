//
//  CollectionSummaryView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/28/21.
//

import SwiftUI

struct CollectionSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @State var collection: Collection
    
    private var ordersInCollection: [OrderInCollection] {
        let orders = collection.orders?.compactMap { $0 as? OrderInCollection } ?? [OrderInCollection]()
        return orders.sorted { $0.order < $1.order }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("COLLECTION")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(collection.name ?? "N/A")")
            }
            
            Divider()
            
            List {
                ForEach(ordersInCollection) { order in
                    if let article = order.article {
                        NavigationLink {
                            ArticleSummaryView(article: article)
                        } label: {
                            HStack {
                                Text("\(order.order + 1)")
                                
                                Spacer()
                                    .frame(width: 20)
                                
                                Text(article.title ?? "")
                                
                                Spacer()
                                
                                Text(article.journal ?? "")
                                
                                Spacer()
                                    .frame(width: 20)
                                
                                Text("\(ToBeCitedDateFormatter.yearOnly.string(from: article.published ?? Date()))")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(collection.name ?? "")
        .padding()
    }
}
