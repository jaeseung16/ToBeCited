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

    @State private var presentAddArticleView = false
    
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
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
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
                Text("Articles")
            }
            
            NavigationView {
                List {
                    ForEach(authors) { author in
                        NavigationLink(destination: AuthorDetailView(author: author)) {
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
                Text("Authors")
            }
        }
        .sheet(isPresented: $presentAddArticleView) {
            AddRISView()
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    private func deleteArticles(offsets: IndexSet) {
        withAnimation {
            offsets.map { articles[$0] }
            .forEach { article in
                viewContext.delete(article)
            }

            saveViewContext()
        }
    }
    
    private func deleteAuthors(offsets: IndexSet) {
        withAnimation {
            offsets.map { authors[$0] }
            .forEach { author in
                viewContext.delete(author)
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

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
