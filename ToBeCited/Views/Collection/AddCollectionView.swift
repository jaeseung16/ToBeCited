//
//  AddCollectionView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/10/21.
//

import SwiftUI

struct AddCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Article.published, ascending: false)],
        animation: .default)
    private var articles: FetchedResults<Article>
    
    @State private var name: String = ""
    @State private var articlesToAdd = [Article]()
    @State private var titleToSearch = ""
    
    private var filteredArticles: Array<Article> {
        articles.filter {
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
                    viewModel.addCollection(name, articles: articlesToAdd)
                    dismiss.callAsFunction()
                }, label: {
                    Text("Save")
                })
            }
        }
    }
    
    private func move(from source: IndexSet, to destination: Int) {
        articlesToAdd.move(fromOffsets: source, toOffset: destination)
    }
    
    private func filteredArticlesView() -> some View {
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
        .listStyle(InsetListStyle())
    }
}
