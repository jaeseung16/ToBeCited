//
//  AddCollectionView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/10/21.
//

import SwiftUI

struct AddCollectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
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
    
    @State private var name: String = ""
    @State private var articlesToAdd = [Article]()
    
    @State var selectedAuthor: Author?
    
    private var filteredArticles: Array<Article> {
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
                
                HStack {
                    Text("NAME")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Collection Name", text: $name, prompt: nil)
                }
                
                List {
                    ForEach(articlesToAdd) { article in
                        Button {
                            if let index = articlesToAdd.firstIndex(of: article) {
                                articlesToAdd.remove(at: index)
                            }
                        } label: {
                            ArticleRowView(article: article)
                        }
                    }
                    .onMove(perform: move)
                }
                
                Divider()
                
                authorsView()
                    .frame(height: 0.25 * geometry.size.height)
                
                Divider()
                
                List {
                    ForEach(filteredArticles) { article in
                        Button {
                            if articlesToAdd.contains(article) {
                                if let index = articlesToAdd.firstIndex(of: article) {
                                    articlesToAdd.remove(at: index)
                                }
                            } else {
                                articlesToAdd.append(article)
                            }
                        } label: {
                            ArticleRowView(article: article)
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding()
        }
    }
    
    private func header() -> some View {
        ZStack {
            HStack {
                Spacer()
                if articlesToAdd.isEmpty {
                    Text("Add a collection")
                } else if articlesToAdd.count == 1 {
                    Text("Add a collection including 1 article")
                } else {
                    Text("Add a collection including \(articlesToAdd.count) articles")
                }
                Spacer()
            }
            
            HStack {
                Button {
                    dismiss.callAsFunction()
                } label: {
                    Text("Cancel")
                }

                Spacer()
                
                Button(action: {
                    viewModel.addCollection(name, articles: articlesToAdd, viewContext: viewContext)
                    dismiss.callAsFunction()
                }, label: {
                    Text("Save")
                })
            }
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
                            AuthorNameView(author: author)
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
    
    private func move(from source: IndexSet, to destination: Int) {
        articlesToAdd.move(fromOffsets: source, toOffset: destination)
    }
}
