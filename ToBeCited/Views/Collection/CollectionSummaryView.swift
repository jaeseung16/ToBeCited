//
//  CollectionSummaryView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/28/21.
//

import SwiftUI

struct CollectionSummaryView: View {
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
                    HStack {
                        Text("\(order.order + 1)")
                        
                        Spacer()
                            .frame(width: 20)
                        
                        Text(order.article?.title ?? "")
                        
                        Spacer()
                        
                        Text(order.article?.journal ?? "")
                        
                        Spacer()
                            .frame(width: 20)
                        
                        Text("\(viewModel.yearOnlyDateFormatter.string(from: order.article?.published ?? Date()))")
                    }
                }
            }
        }
        .navigationTitle(collection.name ?? "")
        .padding()
    }
}
