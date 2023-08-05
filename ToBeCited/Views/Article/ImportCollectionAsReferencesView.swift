//
//  ImportCollectionAsReferencesView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 12/16/21.
//

import SwiftUI

struct ImportCollectionAsReferencesView: View {
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
            ForEach(viewModel.allCollections) { collection in
                if let name = collection.name, name != "" {
                    Button {
                        if collectionsToAdd.contains(collection) {
                            if let index = collectionsToAdd.firstIndex(of: collection) {
                                collectionsToAdd.remove(at: index)
                            }
                        } else {
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
            collection.articles?.forEach { reference in
                if let reference = reference as? Article {
                    guard reference != article else {
                        return
                    }
                    
                    guard let references = reference.references, !references.contains(article) else {
                        return
                    }
                    
                    reference.addToCited(article)
                    article.addToReferences(reference)
                }
            }
        }
        
        viewModel.save { success in
            if !success {
                viewModel.log("ImportCollectionAsReferencesView: Failed to update")
            }
        }
    }
}

