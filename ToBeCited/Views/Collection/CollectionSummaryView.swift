//
//  CollectionSummaryView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/28/21.
//

import SwiftUI

struct CollectionSummaryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @State var collection: Collection
    
    private var ordersInCollection: [OrderInCollection] {
        var orders = [OrderInCollection]()
        
        collection.orders?.forEach { order in
            if let order = order as? OrderInCollection {
                orders.append(order)
            }
        }
        
        return orders.sorted { $0.order < $1.order }
    }
    
    private var articlesInCollection: [Article] {
        ordersInCollection.filter { $0.article != nil} .map { $0.article! }
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
                ForEach(articlesInCollection) { article in
                    NavigationLink {
                        ArticleSummaryView(article: article)
                    } label: {
                        HStack {
                            //Text("\(order.order + 1)")
                            
                            Spacer()
                                .frame(width: 20)
                            
                            Text(article.title ?? "")
                            
                            Spacer()
                            
                            Text(article.journal ?? "")
                            
                            Spacer()
                                .frame(width: 20)
                            
                            Text("\(viewModel.yearOnlyDateFormatter.string(from: article.published ?? Date()))")
                        }
                    }
                }
            }
        }
        .navigationTitle(collection.name ?? "")
        .padding()
    }
}
