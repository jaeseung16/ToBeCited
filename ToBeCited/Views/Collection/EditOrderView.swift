//
//  ArticlesOrderView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/13/21.
//

import SwiftUI

struct EditOrderView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @State var orders: [OrderInCollection]
    @State private var isEdited = false
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            Text("Select and move an article to update the order")
            
            List {
                ForEach(orders) { order in
                    if let article = order.article {
                        ArticleRowView(article: article)
                    }
                }
                .onMove(perform: move)
            }
            .environment(\.editMode, Binding.constant(EditMode.active))
        }
        .padding()
    }
    
    private func header() -> some View {
        HStack {
            Button {
                viewContext.rollback()
                
                dismiss.callAsFunction()
            } label: {
                Text("Dismiss")
            }
        
            Spacer()
        }
    }
    
    private func move(from source: IndexSet, to destination: Int) {
        orders.move(fromOffsets: source, toOffset: destination)
        
        for k in 0..<orders.count {
            orders[k].order = Int64(k)
        }
        
        viewModel.save()
    }
}

