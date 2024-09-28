//
//  SelectArticlesView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/10/21.
//

import SwiftUI

struct SelectReferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @State var article: Article
    @State var selectedAuthor: Author?
    @State var showAlertSameArticle = false
    @State var showAlertCitedArticle = false
    
    @State var references: [Article]
    @State private var titleToSearch = ""
    
    private var filteredArticles: [Article] {
        return viewModel.articles(titleIncluding: titleToSearch)
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
            .navigationTitle(article.title ?? "No Title")
            .alert(Text("An article cannot be its reference"), isPresented: $showAlertSameArticle, actions: {})
            .alert(Text("A citing article cannot be a reference"), isPresented: $showAlertCitedArticle, actions: {})
            .padding()
        }
    }
    
    private func header() -> some View {
        ZStack {
            HStack {
                Button {
                    dismiss.callAsFunction()
                } label: {
                    Text("Dismiss")
                }
                
                Spacer()
            }
            
            HStack {
                Spacer()
                Text("Edit References")
                Spacer()
            }
        }
        
    }
    
    private func authorsView() -> some View {
        VStack {
            Text("CHOOSE AN AUTHOR")
                .font(.callout)
            
            List {
                ForEach(viewModel.allAuthors) { author in
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
        List {
            ForEach(filteredArticles) { article in
                Button {
                    update(reference: article)
                } label: {
                    ArticleRowView(article: article)
                }
            }
        }
        .listStyle(InsetListStyle())
    }
    
    private func update(reference: Article) -> Void {
        if reference == article {
            showAlertSameArticle = true
        } else if let references = reference.references, references.contains(article) {
            showAlertCitedArticle = true
        } else {
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
            
            viewModel.saveAndFetch() { success in
                if !success {
                    viewModel.log("Failed to update references")
                }
            }
        }
    }
}
