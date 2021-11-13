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

    @State private var presentAddArticleView = false
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
            NavigationView {
                List {
                    ForEach(articles) { article in
                        NavigationLink(destination: ArticleDetailView(article: article)) {
                            VStack {
                                HStack {
                                    Text(article.title ?? "")
                                    Spacer()
                                }
                                
                                HStack {
                                    Spacer()
                                    Text(article.published ?? Date(), style: .date)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteArticles)
                }
                .navigationTitle("Articles")
                .toolbar {
                    ToolbarItem {
                        Button(action: {
                            presentAddArticleView = true
                        }) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
            }
            .tabItem {
                Label("Articles", systemImage: "doc.on.doc")
            }
            
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
            .tabItem {
                Label("Authors", systemImage: "person.3")
            }
            
            NavigationView {
                List {
                    ForEach(collections) { collection in
                        NavigationLink(destination: CollectionDetailView(collection: collection)) {
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
            .tabItem {
                Label("Collections", systemImage: "square.stack.3d.up")
            }
        }
        .sheet(isPresented: $presentAddArticleView) {
            AddRISView()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $presentAddCollectionView) {
            AddCollectionView()
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    private func deleteArticles(offsets: IndexSet) {
        withAnimation {
            offsets.map { articles[$0] }
            .forEach { article in
                article.collections?.forEach { collection in
                    if let collection = collection as? Collection {
                        article.removeFromCollections(collection)
                    }
                }
                
                article.orders?.forEach { order in
                    if let order = order as? OrderInCollection {
                        article.removeFromOrders(order)
                    }
                }
                
                viewContext.delete(article)
            }

            saveViewContext()
        }
    }
    
    private func deleteAuthors(offsets: IndexSet) {
        withAnimation {
            offsets.map { authors[$0] }
            .forEach { author in
                if author.articles == nil || author.articles!.count == 0 {
                    viewContext.delete(author)
                } else {
                    // TODO: show alert
                }
            }
            
            saveViewContext()
        }
    }
    
    private func deleteCollections(offsets: IndexSet) {
        withAnimation {
            offsets.map { collections[$0] }
            .forEach { collection in
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
            
            saveViewContext()
        }
    }
    
    private func saveViewContext() -> Void {
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
