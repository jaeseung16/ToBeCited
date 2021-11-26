//
//  CollectionListView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/26/21.
//

import SwiftUI

struct CollectionListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Collection.name, ascending: true)],
        animation: .default)
    private var collections: FetchedResults<Collection>
    
    @State private var presentAddCollectionView = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(collections) { collection in
                    if let name = collection.name, name != "" {
                        NavigationLink(destination: CollectionDetailView(collection: collection, collectionName: name)) {
                            VStack {
                                HStack {
                                    Text(name)
                                    Spacer()
                                }
                                
                                HStack {
                                    Spacer()
                                    Text(collection.lastupd ?? Date(), style: .date)
                                        .font(.callout)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .onDelete(perform: deleteCollections)
            }
            .navigationTitle("Collections")
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        presentAddCollectionView = true
                    }) {
                        Label("Add Collection", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $presentAddCollectionView) {
            AddCollectionView()
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    private func deleteCollections(offsets: IndexSet) {
        withAnimation {
            offsets.map { collections[$0] }.forEach { collection in
                collection.articles?.forEach { article in
                    if let article = article as? Article {
                        article.removeFromCollections(collection)
                    }
                }
                
                collection.orders?.forEach { order in
                    if let order = order as? OrderInCollection {
                        viewContext.delete(order)
                    }
                }
                
                viewContext.delete(collection)
            }
            viewModel.save(viewContext: viewContext)
        }
    }
}

