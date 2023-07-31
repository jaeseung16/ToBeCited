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
    
    @State private var presentAddArticleView = false
    @State private var presentFilterArticleView = false
    
    private var publishedIn: String {
        if let selectedPublishedIn = viewModel.selectedPublishedIn {
            return "\(selectedPublishedIn)"
        } else {
            return ""
        }
    }
    @State private var titleToSearch = ""
    
    private var filteredArticles: [Article] {
        viewModel.articles.filter { article in
            if viewModel.selectedAuthors == nil {
                return true
            } else if let authors = article.authors as? Set<Author>, let selectedAuthors = viewModel.selectedAuthors {
                return !authors.intersection(selectedAuthors).isEmpty
            } else {
                return false
            }
        }
        .filter { article in
            if viewModel.selectedPublishedIn == nil {
                return true
            } else if let published = article.published, let selectedPublishedIn = viewModel.selectedPublishedIn {
                let articlePublicationYear = Calendar.current.dateComponents([.year], from: published)
                return articlePublicationYear.year == selectedPublishedIn
            } else {
                return false
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredArticles) { article in
                    NavigationLink(destination:
                                    ArticleDetailView(article: article,
                                                      title: article.title ?? "Title is not available",
                                                      published: article.published ?? Date())) {
                        ArticleRowView(article: article)
                    }
                }
                .onDelete(perform: deleteArticles)
            }
            .navigationTitle(Text("Articles"))
            .toolbar {
                ToolbarItemGroup {
                    HStack {
                        Button(action: {
                            viewModel.selectedAuthors = nil
                            viewModel.selectedPublishedIn = nil
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
        .onChange(of: titleToSearch) { newValue in
            viewModel.searchArticle(titleToSearch)
        }
        .sheet(isPresented: $presentAddArticleView) {
            AddRISView()
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $presentFilterArticleView) {
            FilterArticleView()
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(viewModel)
        }
    }
    
    private func deleteArticles(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { filteredArticles[$0] } )
        }
    }
}
