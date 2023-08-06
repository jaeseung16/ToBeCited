//
//  EditAuthorsView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 8/6/23.
//

import SwiftUI

struct EditAuthorsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    var article: Article
    @State var authors: [Author]
    @State private var enableSaveButton = false
    @State private var lastNameToSearch = ""
    
    private var filteredAuthors: [Author] {
        viewModel.authors.filter { author in
            if lastNameToSearch == "" {
                return true
            } else if let lastName = author.lastName {
                return lastName.range(of: lastNameToSearch, options: .caseInsensitive) != nil
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
 
                List {
                    ForEach(authors) { author in
                        Button {
                            if let index = authors.firstIndex(of: author) {
                                authors.remove(at: index)
                            }
                        } label: {
                            AuthorNameView(author: author)
                        }
                    }
                }
                .listStyle(InsetListStyle())
                
                Divider()
                
                HStack {
                    Label("Authors (\(filteredAuthors.count))", systemImage: "doc.on.doc")
                    Image(systemName: "magnifyingglass")
                    TextField("LASTNAME", text: $lastNameToSearch, prompt: Text("LASTNAME"))
                        .background(RoundedRectangle(cornerRadius: 8.0).stroke())
                }
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                
                filteredAuthorsView()
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
                Text("Cancel")
            }

            Spacer()
            
            Button(action: {
                viewModel.update(article: article, with: authors)
                dismiss.callAsFunction()
            }, label: {
                Text("Save")
            })
        }
    }
    
    private func filteredAuthorsView() -> some View {
        VStack {
            List {
                ForEach(filteredAuthors) { author in
                    Button {
                        if authors.contains(author) {
                            if let index = authors.firstIndex(of: author) {
                                authors.remove(at: index)
                            }
                        } else {
                            authors.append(author)
                        }
                    } label: {
                        AuthorNameView(author: author)
                        Spacer()
                        Label("\(author.articles?.count ?? 0)", systemImage: "doc.on.doc")
                            .font(.callout)
                            .foregroundColor(Color.secondary)
                    }
                }
            }
            .listStyle(InsetListStyle())
        }
    }
     
}
