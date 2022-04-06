//
//  FilterArticleView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/21/21.
//

import SwiftUI

struct FilterArticleView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Author.lastName, ascending: true),
                          NSSortDescriptor(keyPath: \Author.firstName, ascending: true),
                          NSSortDescriptor(keyPath: \Author.created, ascending: false)],
        animation: .default)
    private var authors: FetchedResults<Author>
    
    @State private var lastNameToSearch = ""
    @State var publishedIn: String
    @State private var selectedAuthor = UUID()
    
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }
    
    private var filteredAuthors: [Author] {
        authors.filter { author in
            if lastNameToSearch == "" {
                return false
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
                
                selectedPublishedView()
                
                selectedAuthorView()
                
                Divider()
                
                HStack {
                    Text("SELECT AN AUTHOR")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                /*
                Picker("SELECT AN AUTHOR", selection: $selectedAuthor) {
                    ForEach(authors) { author in
                        if let uuid = author.uuid {
                            Text(viewModel.nameComponents(of: author).formatted(.name(style: .long)))
                                .tag(uuid)
                        }
                    }
                }
                .onChange(of: selectedAuthor) { _ in
                    viewModel.selectedAuthor = authors.first { $0.uuid == selectedAuthor }
                }
                */
                List {
                    ForEach(filteredAuthors) { author in
                        if author.lastName != nil && author.lastName != "" {
                            NavigationLink(destination: AuthorDetailView(author: author,
                                                                         firstName: author.firstName ?? "",
                                                                         middleName: author.middleName ?? "",
                                                                         lastName: author.lastName ?? "",
                                                                         nameSuffix: author.nameSuffix ?? "",
                                                                         orcid: author.orcid ?? "")) {
                                AuthorNameView(author: author)
                            }
                        }
                    }
                }
                
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
    
    private func selectedAuthorView() -> some View {
        HStack {
            Text("AUTHOR")
                .font(.caption)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            /*
            if viewModel.selectedAuthor == nil {
                Text("N/A")
                    .foregroundColor(.secondary)
            } else {
                Text("\(viewModel.nameComponents(of: viewModel.selectedAuthor!).formatted(.name(style: .long)))")
            }
            */
            TextField("AUTHOR", text: $lastNameToSearch, prompt: Text("Last Name"))
                .onSubmit {
                    viewModel.selectedAuthors = Set(filteredAuthors)
                }
            
            Spacer()
            
            Button {
                viewModel.selectedAuthor = nil
                viewModel.selectedAuthors = nil
            } label: {
                Text("reset")
            }
        }
    }
    
    private var yearFormatter: NumberFormatter {
        let dateFormatter = NumberFormatter()
        dateFormatter.numberStyle = .none
        return dateFormatter
    }
    
    private func selectedPublishedView() -> some View {
        HStack {
            Text("PUBLISHED IN")
                .font(.caption)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            TextField("Publication Year", text: $publishedIn, prompt: Text("2000"))
                .onSubmit {
                    print("publishedIn=\(publishedIn)")
                    
                    if let publishedIn = numberFormatter.number(from: publishedIn) as? Int {
                        viewModel.selectedPublishedIn = publishedIn
                    } else {
                        publishedIn = ""
                        viewModel.selectedPublishedIn = nil
                    }
                }
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button {
                publishedIn = ""
                viewModel.selectedPublishedIn = nil
            } label: {
                Text("reset")
            }
        }
    }
}
