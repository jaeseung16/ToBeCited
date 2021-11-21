//
//  ContentView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/17/21.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var viewModel: ToBeCitedViewModel

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Article.published, ascending: false)],
        animation: .default)
    private var articles: FetchedResults<Article>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Author.lastName, ascending: true)],
        animation: .default)
    private var authors: FetchedResults<Author>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Collection.name, ascending: true)],
        animation: .default)
    private var collections: FetchedResults<Collection>
    
    @State private var presentAddCollectionView = false
    
    private func getContacts(of author: Author) -> [AuthorContact] {
        let predicate = NSPredicate(format: "author == %@", argumentArray: [author])
        let sortDescriptor = NSSortDescriptor(keyPath: \AuthorContact.created, ascending: false)
        
        let fetchRequest = NSFetchRequest<AuthorContact>(entityName: "AuthorContact")
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = predicate
        
        let fc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fc.performFetch()
        } catch {
            NSLog("Failed fetch contacts with author = \(author)")
        }
        
        return fc.fetchedObjects ?? [AuthorContact]()
    }
    
    var body: some View {
        TabView {
            ArticleListView()
                .tabItem {
                    Label("Articles", systemImage: "doc.on.doc")
                }
            
            authorsTabView()
                .tabItem {
                    Label("Authors", systemImage: "person.3")
                }
            
            collectionsTabView()
                .tabItem {
                    Label("Collections", systemImage: "square.stack.3d.up")
                }
        }
        .sheet(isPresented: $presentAddCollectionView) {
            AddCollectionView()
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    private func authorsTabView() -> some View {
        NavigationView {
            List {
                ForEach(authors) { author in
                    NavigationLink(destination: AuthorDetailView(author: author, contacts: getContacts(of: author))) {
                        HStack {
                            Text(author.lastName ?? "")
                            Text(author.firstName ?? "")
                            Text(author.middleName ?? "")
                        }
                    }
                }
                .onDelete(perform: deleteAuthors)
            }
            .navigationTitle("Authors")
        }
    }
    
    private func collectionsTabView() -> some View {
        NavigationView {
            List {
                ForEach(collections) { collection in
                    NavigationLink(destination: CollectionDetailView(collection: collection, collectionName: collection.name ?? "")) {
                        HStack {
                            Text(collection.name ?? "")
                            Text(collection.lastupd ?? Date(), style: .date)
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
    }
  
    private func deleteAuthors(offsets: IndexSet) {
        withAnimation {
            offsets.map { authors[$0] }.forEach { author in
                if author.articles == nil || author.articles!.count == 0 {
                    viewContext.delete(author)
                }
            }
            viewModel.save(viewContext: viewContext)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(ToBeCitedViewModel.shared)
    }
}
