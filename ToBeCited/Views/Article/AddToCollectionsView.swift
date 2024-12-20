//
//  AddToCollectionsView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 12/16/21.
//

import SwiftUI

struct AddToCollectionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
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
                            } else {
                                collectionsToAdd.append(collection)
                            }
                        } label: {
                            collectionRowView(name: name, lastupd: collection.lastupd ?? Date())
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
            ForEach(viewModel.allCollections) { collection in
                if let name = collection.name, name != "" {
                    Button {
                        if let collections = article.collections, !collections.contains(collection) && collectionsToAdd.firstIndex(of: collection) == nil {
                            collectionsToAdd.append(collection)
                        }
                    } label: {
                        collectionRowView(name: name, lastupd: collection.lastupd ?? Date())
                    }
                }
            }
        }
    }
    
    private func update() -> Void {
        viewModel.add(article: article, to: collectionsToAdd)
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

