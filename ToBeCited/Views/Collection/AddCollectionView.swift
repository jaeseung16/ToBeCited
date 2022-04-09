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
    
    @State private var lastNameToSearch = ""
    @State var selectedAuthor: Author?
    private var filteredAuthors: [Author] {
        authors.filter { author in
            if lastNameToSearch.isEmpty {
                return true
            } else if let lastName = author.lastName {
                return lastName.range(of: lastNameToSearch, options: .caseInsensitive) != nil
            } else {
                return false
            }
        }
    }
    
    @State private var titleToSearch = ""
    private var filteredArticles: Array<Article> {
        articles
            .filter {
                guard let authors = $0.authors as? Set<Author>, let author = selectedAuthor else {
                    return true
                }
                return authors.contains(author)
            }
            .filter {
                if titleToSearch.isEmpty {
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
                
                articlesView()
                
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
            HStack {
                Text("FIND AN AUTHOR")
                    .font(.callout)
                
                Text("\(filteredAuthors.count)")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                TextField("AUTHOR", text: $lastNameToSearch, prompt: Text("Last Name"))
                    .multilineTextAlignment(.center)
                
                Button {
                    lastNameToSearch = ""
                    selectedAuthor = nil
                } label: {
                    Image(systemName: "clear")
                }
            }
            
            List {
                ForEach(filteredAuthors) { author in
                    Button {
                        selectedAuthor = author
                    } label: {
                        HStack {
                            AuthorNameView(author: author)
                            Spacer()
                            Label("\(author.articles?.count ?? 0)", systemImage: "doc.on.doc")
                                .font(.callout)
                                .foregroundColor(Color.secondary)
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
    
    private func articlesView() -> some View {
        VStack {
            HStack {
                Text("FIND ARTICLES")
                    .font(.callout)
                
                Text("\(filteredArticles.count)")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                TextField("ARTICLE", text: $titleToSearch, prompt: Text("TITLE"))
                    .multilineTextAlignment(.center)
                
                Button {
                    titleToSearch = ""
                } label: {
                    Image(systemName: "clear")
                }
            }
        
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
    }
}
