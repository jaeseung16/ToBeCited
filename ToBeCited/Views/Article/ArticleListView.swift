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
    
    var body: some View {
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
        .sheet(isPresented: $presentAddArticleView) {
            AddRISView()
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
