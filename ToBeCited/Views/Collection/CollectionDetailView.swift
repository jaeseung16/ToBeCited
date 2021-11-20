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
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @State var collection: Collection
    
    @State var edited = false
    @State private var presentEditOrderView = false
    @State private var presentEditCollectionView = false
    @State private var presentExportCollectionView = false
    @State var collectionName = ""
    
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
            header()
            
            Divider()
            
            HStack {
                Text("NAME")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("\(collection.name ?? "N/A")", text: $collectionName, prompt: nil)
                    .onSubmit {
                        collection.name = collectionName
                        edited = true
                    }
            }
            
            List {
                ForEach(ordersInCollection) { order in
                    HStack {
                        Text(order.article?.title ?? "")
                        
                        Spacer()
                        
                        Text("\(order.order + 1)")
                    }
                }
                .onDelete(perform: delete)
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
            EditOrderView(orders: ordersInCollection)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $presentEditCollectionView) {
            EditCollectionView(collection: collection, articlesInCollection: articlesInCollection)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $presentExportCollectionView) {
            ExportCollectionView(collection: collection)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(viewModel)
        }

    }
    
    private func header() -> some View {
        HStack {
            Button {
                viewContext.rollback()
                
                edited = false
            } label: {
                Text("Cancel")
            }
            .disabled(!edited)
            
            Spacer()
            
            Button {
                presentEditCollectionView = true
            } label: {
                Text("Update articles")
            }
            
            Spacer()
            
            Button {
                presentEditOrderView = true
            } label: {
                Text("Update the order")
            }
            
            Spacer()
            
            Button {
                viewModel.export(collection: collection)
                presentExportCollectionView = true
            } label: {
                Text("Export")
            }
            
            Spacer()
            
            Button {
                viewModel.save(viewContext: viewContext)
                
                edited = false
            } label: {
                Text("Save")
            }
            .disabled(!edited)
        }
    }
    
    private func delete(offsets: IndexSet) {
        withAnimation {
            offsets.map { ordersInCollection[$0] }.forEach { order in
                order.article?.removeFromCollections(collection)
                viewContext.delete(order)
            }
            
            if let offset = offsets.first {
                collection.orders?.forEach({ order in
                    if let order = order as? OrderInCollection {
                        if order.order > offset {
                            order.order -= 1
                        }
                    }
                })
            }

            viewModel.save(viewContext: viewContext)
        }
    }
}
