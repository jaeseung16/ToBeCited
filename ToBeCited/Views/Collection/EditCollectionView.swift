//
//  EditCollectionView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/14/21.
//

import SwiftUI

struct EditCollectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Article.published, ascending: false)],
        animation: .default)
    private var articles: FetchedResults<Article>
    
    var collection: Collection
    
    @State var articlesInCollection: [Article]
    @State var titleToSearch = ""
    
    private var filteredArticles: Array<Article> {
        articles.filter {
            if titleToSearch == "" {
                return true
            } else if let title = $0.title {
                return title.range(of: titleToSearch, options: .caseInsensitive) != nil
            } else {
                return false
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                Text("The collection contains \(articlesInCollection.count) \(articlesInCollection.count == 1 ? "article" : "articles")")
                
                List {
                    ForEach(articlesInCollection) { article in
                        Button {
                            if let index = articlesInCollection.firstIndex(of: article) {
                                articlesInCollection.remove(at: index)
                                viewModel.update(collection: collection, with: articlesInCollection, viewContext: viewContext)
                            }
                        } label: {
                            ArticleRowView(article: article)
                        }
                    }
                }
                .listStyle(InsetListStyle())
                
                Divider()
                
                HStack {
                    Label("Articles (\(filteredArticles.count))", systemImage: "doc.on.doc")
                    Image(systemName: "magnifyingglass")
                    TextField("WORDS IN TITLE", text: $titleToSearch, prompt: Text("WORDS IN TITLE"))
                        .background(RoundedRectangle(cornerRadius: 8.0).stroke())
                }
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                
                filteredArticlesView()
                    .frame(height: 0.3 * geometry.size.height)
            }
            .padding()
        }
    }
    
    private func header() -> some View {
        HStack {
            Button {
                dismiss.callAsFunction()
            } label: {
                Text("Dismiss")
            }

            Spacer()
        }
    }
    
    private func filteredArticlesView() -> some View {
        VStack {
            List {
                ForEach(filteredArticles) { article in
                    Button {
                        if articlesInCollection.contains(article) {
                            if let index = articlesInCollection.firstIndex(of: article) {
                                articlesInCollection.remove(at: index)
                            }
                        } else {
                            articlesInCollection.append(article)
                        }
                        
                        viewModel.update(collection: collection, with: articlesInCollection, viewContext: viewContext)
                    } label: {
                        ArticleRowView(article: article)
                    }
                }
            }
            .listStyle(InsetListStyle())
        }
    }
     
}

