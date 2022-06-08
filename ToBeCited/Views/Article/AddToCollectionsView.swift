//
//  AddToCollectionsView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 12/16/21.
//

import SwiftUI

struct AddToCollectionsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Collection.name, ascending: true)],
        animation: .default)
    private var collections: FetchedResults<Collection>
    
    @State var article: Article
    @State var collectionsToAdd = [Collection]()
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            List {
                ForEach(collectionsToAdd) { collection in
                    if let name = collection.name, name != "" {
                        Button {
                            if let index = collectionsToAdd.firstIndex(of: collection) {
                                collectionsToAdd.remove(at: index)
                            }
                        } label: {
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
            }
            
            Divider()
            
            collectionListView()
        }
        .padding()
    }
    
    private func header() -> some View {
        HStack {
            Button {
                dismiss.callAsFunction()
            } label: {
                Text("Dismiss")
            }

            Spacer()
            
            Button {
                update()
                dismiss.callAsFunction()
            } label: {
                Text("Save")
            }
        }
    }
    
    private func collectionListView() -> some View {
        List {
            ForEach(collections) { collection in
                if let name = collection.name, name != "" {
                    Button {
                        if let collections = article.collections, !collections.contains(collection) {
                            collectionsToAdd.append(collection)
                        }
                    } label: {
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
        }
    }
    
    private func update() -> Void {
        for collection in collectionsToAdd {
            let count = collection.articles == nil ? 0 : collection.articles!.count
            
            let order = OrderInCollection(context: viewContext)
            order.collectionId = collection.uuid
            order.articleId = article.uuid
            order.order = Int64(count)
            collection.addToOrders(order)
            article.addToOrders(order)
            
            article.addToCollections(collection)
        }
        
        viewModel.save(viewContext: viewContext) { success in
            if !success {
                viewModel.log("AddToCollectionsView: Failed to update")
            }
        }
    }
    
}

