//
//  ArticleListView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/21/21.
//

import SwiftUI

struct ArticleListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var viewModel: ToBeCitedViewModel

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Article.published, ascending: false)],
        animation: .default)
    private var articles: FetchedResults<Article>
    
    @State private var presentAddArticleView = false
    @State private var presentFilterArticleView = false
    
    @State private var author: Author?
    @State private var publishedIn: Int?
    @State private var titleToSearch = ""
    
    private var filteredArticles: [Article] {
        articles.filter { article in
            if author == nil {
                return true
            } else if let authors = article.authors as? Set<Author> {
                return authors.contains(author!)
            } else {
                return false
            }
        }
        .filter { article in
            if publishedIn == nil {
                return true
            } else if let published = article.published {
                let articlePublicationYear = Calendar.current.dateComponents([.year], from: published)
                return articlePublicationYear.year == publishedIn
            } else {
                return false
            }
        }
        .filter { article in
            if titleToSearch == "" {
                return true
            } else if let title = article.title {
                return title.contains(titleToSearch)
            } else {
                return false
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredArticles) { article in
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
                ToolbarItemGroup {
                    HStack {
                        Button(action: {
                            presentFilterArticleView = true
                        }) {
                            Label("Filter", systemImage: "line.horizontal.3.decrease.circle")
                        }
                        
                        Button(action: {
                            presentAddArticleView = true
                        }) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
            }
            
        }
        .searchable(text: $titleToSearch)
        .sheet(isPresented: $presentAddArticleView) {
            AddRISView()
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $presentFilterArticleView) {
            FilterArticleView(author: $author, publishedIn: $publishedIn)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(viewModel)
        }
    }
    
    private func deleteArticles(offsets: IndexSet) {
        withAnimation {
            offsets.map { articles[$0] }.forEach { article in
                article.collections?.forEach { collection in
                    if let collection = collection as? Collection {
                        article.removeFromCollections(collection)
                    }
                }
                
                // TODO: Reorder articles in collection
                // TODO: Move these operations to viewModel
                
                article.orders?.forEach { order in
                    if let order = order as? OrderInCollection {
                        article.removeFromOrders(order)
                    }
                }
                
                viewContext.delete(article)
            }
            viewModel.save(viewContext: viewContext)
        }
    }
}

struct ArticleListView_Previews: PreviewProvider {
    static var previews: some View {
        ArticleListView()
    }
}
