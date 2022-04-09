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
    @State private var titleToSearch = ""
    
    private var filteredCollections: [Collection] {
        collections.filter { collection in
            if titleToSearch == "" {
                return true
            } else if let name = collection.name {
                return name.range(of: titleToSearch, options: .caseInsensitive) != nil
            } else {
                return false
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredCollections) { collection in
                    if let name = collection.name, name != "" {
                        NavigationLink(destination: CollectionDetailView(collection: collection, collectionName: name)) {
                            VStack {
                                HStack {
                                    Text(name)
                                    Spacer()
                                    Label("\(collection.articles?.count ?? 0)", systemImage: "doc.on.doc")
                                        .font(.callout)
                                        .foregroundColor(Color.secondary)
                                }
                            }
                        }
                    }
                }
                .onDelete(perform: deleteCollections)
            }
            .navigationTitle("Collections")
            .searchable(text: $titleToSearch)
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
                .environmentObject(viewModel)
        }
    }
    
    private func deleteCollections(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { filteredCollections[$0] }, viewContext: viewContext)
        }
    }
}

