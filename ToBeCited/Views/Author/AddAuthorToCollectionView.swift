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
                            collectionRowView(name: name, lastupd: collection.lastupd ?? Date())
                        }
                    }
                }
            }
            
            Divider()
            
            HStack {
                Label("COLLECTIONS (\(viewModel.allCollections.count))", systemImage: "square.stack.3d.up")
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
            ForEach(viewModel.allCollections) { collection in
                if let name = collection.name, name != "" {
                    Button {
                        if collectionsToAdd.firstIndex(of: collection) == nil {
                            collectionsToAdd.append(collection)
                        }
                    } label: {
                        collectionRowView(name: name, lastupd: collection.lastupd ?? Date())
                    }
                }
            }
        }
        .listStyle(InsetListStyle())
    }
    
    private func collectionRowView(name: String, lastupd: Date) -> some View {
        VStack {
            HStack {
                Text(name)
                Spacer()
            }
            
            HStack {
                Spacer()
                Text(lastupd, style: .date)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
    }
    
}

