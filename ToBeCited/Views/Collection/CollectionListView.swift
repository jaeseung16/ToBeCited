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
    
    @State private var presentAddCollectionView = false
    @State private var titleToSearch = ""
    
    private var filteredCollections: [Collection] {
        viewModel.collections.filter { collection in
            if titleToSearch == "" {
                return true
            } else if let name = collection.name {
                return name.range(of: titleToSearch, options: .caseInsensitive) != nil
            } else {
                return false
            }
        }
    }
    
    @State private var selectedCollection: Collection?
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedCollection) {
                ForEach(filteredCollections) { collection in
                    NavigationLink(value: collection) {
                        HStack {
                            Text(collection.name ?? "")
                            Spacer()
                            Label("\(collection.articles?.count ?? 0)", systemImage: "doc.on.doc")
                                .font(.callout)
                                .foregroundColor(Color.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteCollections)
            }
            .navigationTitle("Collections")
            .searchable(text: $titleToSearch)
            .toolbar {
                ToolbarItem {
                    Button {
                        presentAddCollectionView = true
                    } label: {
                        Label("Add Collection", systemImage: "plus")
                    }
                }
            }
            .refreshable {
                viewModel.fetchAll()
            }
        } detail: {
            if let collection = selectedCollection {
                CollectionDetailView(collection: collection, collectionName: collection.name ?? "")
                    .id(collection)
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(viewModel)
            }
        }
        .sheet(isPresented: $presentAddCollectionView) {
            AddCollectionView()
                .environmentObject(viewModel)
        }
        .onAppear() {
            if viewModel.selectedTab != .collections {
                viewModel.selectedTab = .collections
            }
        }
    }
    
    private func deleteCollections(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { filteredCollections[$0] })
        }
    }
}

