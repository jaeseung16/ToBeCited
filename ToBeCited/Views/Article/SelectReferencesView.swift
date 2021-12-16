//
//  SelectArticlesView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/10/21.
//

import SwiftUI

struct SelectReferencesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @State var article: Article
    @State var selectedAuthor: Author?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Article.published, ascending: false)],
        animation: .default)
    private var articles: FetchedResults<Article>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Author.lastName, ascending: true),
                          NSSortDescriptor(keyPath: \Author.firstName, ascending: true),
                          NSSortDescriptor(keyPath: \Author.created, ascending: false)],
        animation: .default)
    private var authors: FetchedResults<Author>
    
    @State var references: [Article]
    
    private var filteredArticles: [Article] {
        articles.filter { article in
            if let authors = article.authors as? Set<Author>, let author = selectedAuthor {
                return authors.contains(author)
            }
            return false
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                List {
                    ForEach(references) { reference in
                        Button {
                            update(reference: reference)
                        } label: {
                            ArticleRowView(article: reference)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
                Divider()
                
                authorsView()
                    .frame(height: 0.25 * geometry.size.height)
                
                Divider()
                
                filteredArticlesView()
                    .frame(height: 0.3 * geometry.size.height)
            }
            .navigationTitle(article.title ?? "No Title")
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
    
    private func authorsView() -> some View {
        VStack {
            Text("CHOOSE AN AUTHOR")
                .font(.callout)
            
            List {
                ForEach(authors) { author in
                    Button {
                        selectedAuthor = author
                    } label: {
                        HStack {
                            Text(author.firstName ?? "")
                            
                            Text(author.lastName ?? "")
                            
                            Spacer()
                            
                            Text("\(author.articles?.count ?? 0)")
                        }
                    }
                    .foregroundColor(author == selectedAuthor ? .primary : .secondary)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private func filteredArticlesView() -> some View {
        VStack {
            if let author = selectedAuthor, let lastName = author.lastName {
                HStack {
                    Text("ARTICLES BY")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                        .frame(width: 50)
                    Text(author.firstName ?? "")
                    Text(lastName)
                    Spacer()
                }
            }
            
            List {
                ForEach(filteredArticles) { reference in
                    Button {
                        update(reference: reference)
                    } label: {
                        ArticleRowView(article: reference)
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private func update(reference: Article) -> Void {
        if references.contains(reference) {
            if let index = references.firstIndex(of: reference) {
                references.remove(at: index)
            }
            article.removeFromReferences(reference)
            reference.removeFromCited(article)
        } else {
            references.append(reference)
            article.addToReferences(reference)
            reference.addToCited(article)
        }
        
        viewModel.save(viewContext: viewContext)
    }
}
