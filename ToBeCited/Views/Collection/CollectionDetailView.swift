//
//  CollectionDetailView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/10/21.
//

import SwiftUI

struct CollectionDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State var collection: Collection
    
    @State var edited = false
    @State private var presentEditOrderView = false
    
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
            header()
            
            Divider()
            
            List {
                ForEach(ordersInCollection) { order in
                    HStack {
                        Text(order.article?.title ?? "")
                        
                        Spacer()
                        
                        Text("\(order.order + 1)")
                    }
                }
            }
        }
        .navigationTitle(collection.name ?? "")
        .onDisappear {
            print("onDisappear")
            if viewContext.hasChanges {
                viewContext.rollback()
            }
        }
        .padding()
        .sheet(isPresented: $presentEditOrderView) {
            
        } content: {
            EditOrderView(orders: ordersInCollection)
        }

    }
    
    private func header() -> some View {
        HStack {
            Spacer()
            
            Button {
                viewContext.rollback()
                
                edited = false
            } label: {
                Text("Cancel")
            }
            
            Spacer()
            
            Button {
                presentEditOrderView = true
            } label: {
                Text("Edit the order")
            }
            
            Spacer()
            
            Button {
                update()
                
                edited = false
            } label: {
                Text("Save")
            }
            .disabled(!edited)

            Spacer()
        }
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
