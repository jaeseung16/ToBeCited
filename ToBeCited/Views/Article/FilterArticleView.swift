//
//  FilterArticleView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/21/21.
//

import SwiftUI

struct FilterArticleView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @State private var lastNameToSearch: String = ""
    @State var publishedIn: String = ""
    @State private var selectedAuthor = UUID()
    
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }
    
    private var filteredAuthors: [Author] {
        if lastNameToSearch.isEmpty {
            return [Author]()
        } else {
            return viewModel.authors(lastNameIncluding: lastNameToSearch)
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
                    Text("SELECTED AUTHORS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                filteredAuthorList()
                
            }
            .padding()
        }
    }
    
    private func filteredAuthorList() -> some View {
        List {
            ForEach(filteredAuthors) { author in
                if author.lastName != nil && author.lastName != "" {
                    Button {
                        if viewModel.selectedAuthors != nil {
                            if selected(author) {
                                viewModel.selectedAuthors!.remove(author)
                            } else {
                                viewModel.selectedAuthors!.insert(author)
                            }
                        }
                    } label: {
                        filteredAuthorLabel(author)
                    }
                }
            }
        }
    }
    
    private func filteredAuthorLabel(_ author: Author) -> some View {
        HStack {
            AuthorNameView(author: author)
            Spacer()
            Label("\(author.articles?.count ?? 0)", systemImage: "doc.on.doc")
                .font(.callout)
                .foregroundColor(Color.secondary)
            Divider()
            if selected(author) {
                Image(systemName: "checkmark.square")
            } else {
                Image(systemName: "square")
            }
        }
    }
    
    private func selected(_ author: Author) -> Bool {
        if let selectedAuthors = viewModel.selectedAuthors {
            return selectedAuthors.contains(author)
        } else {
            return false
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
            
            TextField("AUTHOR", text: $lastNameToSearch, prompt: Text("Last Name"))
                .onSubmit {
                    viewModel.selectedAuthors = Set(filteredAuthors)
                }
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button {
                lastNameToSearch = ""
                viewModel.selectedAuthors = nil
            } label: {
                Image(systemName: "clear")
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
                Image(systemName: "clear")
            }
        }
    }
}
