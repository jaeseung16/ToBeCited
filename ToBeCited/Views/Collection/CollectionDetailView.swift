//
//  CollectionDetailView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/10/21.
//

import SwiftUI

struct CollectionDetailView: View {
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @State var collection: Collection
    
    @State var edited = false
    @State private var presentEditOrderView = false
    @State private var presentEditCollectionView = false
    @State private var presentExportCollectionView = false
    @State var collectionName = ""
    
    private var ordersInCollection: [OrderInCollection] {
        let orders = collection.orders?.compactMap { $0 as? OrderInCollection } ?? [OrderInCollection]()
        return orders.sorted { $0.order < $1.order }
    }
    
    private var articlesInCollection: [Article] {
        ordersInCollection.filter { $0.article != nil} .map { $0.article! }
    }
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            info()
            
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

            NavigationStack {
                List {
                    ForEach(ordersInCollection) { order in
                        if let article = order.article {
                            NavigationLink(value: order) {
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
                .navigationDestination(for: OrderInCollection.self) { order in
                    if let article = order.article {
                        ArticleSummaryView(article: article)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle(collection.name ?? "")
        .padding()
        .sheet(isPresented: $presentEditOrderView) {
            EditOrderView(orders: ordersInCollection)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $presentEditCollectionView) {
            EditCollectionView(collection: collection, articlesInCollection: articlesInCollection)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $presentExportCollectionView) {
            ExportCollectionView(collection: collection)
                .environmentObject(viewModel)
        }
    }
    
    private func header() -> some View {
        VStack {
            HStack {
                Spacer()
                
                Button {
                    Task {
                        await viewModel.export(collection: collection)
                        presentExportCollectionView = true
                    }
                } label: {
                    Label("EXPORT", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
    
    private func info() -> some View {
        VStack {
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
                    
                    viewModel.saveAndFetch()
                    
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
        }
    }
    
    private func delete(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { ordersInCollection[$0] }, at: offsets, in: collection)
        }
    }
}
