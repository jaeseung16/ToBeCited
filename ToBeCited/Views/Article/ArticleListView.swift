//
//  ArticleListView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/21/21.
//

import SwiftUI
import CoreSpotlight

struct ArticleListView: View {
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
    
    @State private var selectedArticle: Article?
    
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
        NavigationSplitView {
            List(selection: $selectedArticle) {
                ForEach(filteredArticles) { article in
                    NavigationLink(value: article) {
                        ArticleRowView(article: article)
                    }
                }
                .onDelete(perform: deleteArticles)
            }
            .navigationTitle(Text("Articles"))
            .toolbar {
                ToolbarItemGroup {
                    HStack {
                        Button {
                            reset()
                            presentFilterArticleView = true
                        } label: {
                            Label("Filter", systemImage: "line.horizontal.3.decrease.circle")
                        }
                        
                        Button {
                            reset()
                            presentAddArticleView = true
                        } label: {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
            }
        } detail: {
            if let article = selectedArticle {
                ArticleDetailView(article: article,
                                  title: article.title ?? "Title is not available",
                                  published: article.published ?? Date())
                .id(article)
            }
        }
        .searchable(text: $viewModel.articleSearchString)
        .onChange(of: viewModel.articleSearchString) {
            viewModel.searchArticle()
        }
        .sheet(isPresented: $presentAddArticleView) {
            AddRISView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $presentFilterArticleView) {
            FilterArticleView()
                .environmentObject(viewModel)
        }
        .onContinueUserActivity(CSSearchableItemActionType) { activity in
            Task(priority: .userInitiated) {
                if let article = await viewModel.continueActivity(activity) as? Article {
                    viewModel.articleSearchString = article.title ?? ""
                    selectedArticle = article
                }
            }
        }
        .onAppear() {
            if viewModel.selectedTab != .articles {
                viewModel.selectedTab = .articles
            }
        }
    }
    
    private func deleteArticles(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { filteredArticles[$0] } )
        }
    }
    
    private func reset() {
        viewModel.articleSearchString = ""
        viewModel.selectedAuthors = nil
        viewModel.selectedPublishedIn = nil
    }
}
