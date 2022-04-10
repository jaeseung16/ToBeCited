//
//  CollectionDetailView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/10/21.
//

import SwiftUI

struct CollectionDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
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
                Button {
                    collectionName = collection.name ?? ""
                    
                    edited = false
                } label: {
                    Label("CANCEL", systemImage: "gobackward")
                }
                .disabled(!edited)
                
                Button {
                    collection.name = collectionName
                    
                    viewModel.save(viewContext: viewContext)
                    
                    edited = false
                } label: {
                    Label("SAVE", systemImage: "square.and.arrow.down")
                }
                .disabled(!edited)
                
                Spacer()
            }
            
            HStack {
                Text("NAME")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("\(collection.name ?? "N/A")", text: $collectionName, prompt: nil)
                    .onSubmit {
                        if collectionName == "" {
                            collectionName = collection.name ?? "N/A"
                        } else {
                            edited = true
                        }
                    }
            }
            
            Divider()
            
            HStack {
                Spacer()
                Text("EDIT")
                
                Button {
                    presentEditCollectionView = true
                } label: {
                    Label("ARTICLES", systemImage: "doc.on.doc")
                }
                
                Button {
                    presentEditOrderView = true
                } label: {
                    Label("ORDER", systemImage: "123.rectangle")
                }
            }

            List {
                ForEach(ordersInCollection) { order in
                    if let article = order.article {
                        NavigationLink {
                            if let article = order.article {
                                ArticleSummaryView(article: article)
                            }
                        } label: {
                            HStack {
                                Text("\(order.order + 1)")
                                
                                Spacer()
                                    .frame(width: 20)
                                
                                ArticleRowView(article: article)
                            }
                        }
                    }
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle(collection.name ?? "")
        .padding()
        .sheet(isPresented: $presentEditOrderView) {
            EditOrderView(orders: ordersInCollection)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(viewModel)
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
        VStack {
            HStack {
                Spacer()
                
                Button {
                    viewModel.export(collection: collection)
                    presentExportCollectionView = true
                } label: {
                    Label("EXPORT", systemImage: "square.and.arrow.up")
                }
            }
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
