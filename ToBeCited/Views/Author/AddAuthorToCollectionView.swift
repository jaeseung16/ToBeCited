//
//  AddAuthorToCollectionView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 4/10/22.
//

import SwiftUI

struct AddAuthorToCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Collection.name, ascending: true)],
        animation: .default)
    private var collections: FetchedResults<Collection>
    
    @State var articles: [Article]
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
            
            HStack {
                Label("COLLECTIONS (\(collections.count))", systemImage: "square.stack.3d.up")
                    .font(.callout)
                Spacer()
            }
           
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
                viewModel.add(articles, to: collectionsToAdd)
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
                        collectionsToAdd.append(collection)
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
        .listStyle(InsetListStyle())
    }
    
}

