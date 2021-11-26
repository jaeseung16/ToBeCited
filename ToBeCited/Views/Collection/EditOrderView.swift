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
    
    @State var orders: [OrderInCollection]
    @State private var isEdited = false
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            Text("Select and move an article to update the order")
            
            List {
                ForEach(orders) { order in
                    HStack {
                        Text(order.article?.title ?? "")
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
        
        update()
    }
    
    private func update() -> Void {
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

