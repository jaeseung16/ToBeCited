//
//  AuthorListView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/28/21.
//

import SwiftUI
import CoreData

struct AuthorListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Author.lastName, ascending: true),
                                    NSSortDescriptor(keyPath: \Author.firstName, ascending: true),
                                    NSSortDescriptor(keyPath: \Author.created, ascending: false)],
                  animation: .default)
    private var authors: FetchedResults<Author>

    @State private var lastNameToSearch = ""
    
    private var filteredAuthors: [Author] {
        authors.filter { author in
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
        NavigationView {
            List {
                ForEach(filteredAuthors) { author in
                    NavigationLink(destination: AuthorDetailView(author: author,
                                                                 firstName: author.firstName ?? "",
                                                                 middleName: author.middleName ?? "",
                                                                 lastName: author.lastName ?? "",
                                                                 nameSuffix: author.nameSuffix ?? "",
                                                                 orcid: author.orcid ?? "")) {
                        HStack {
                            AuthorNameView(author: author)
                            Spacer()
                            Label("\(author.articles?.count ?? 0)", systemImage: "doc.on.doc")
                                .font(.callout)
                                .foregroundColor(Color.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteAuthors)
            }
            .navigationTitle(Text("Authors"))
            .searchable(text: $lastNameToSearch)
        }
    }
    
    private func deleteAuthors(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { filteredAuthors[$0] }, viewContext: viewContext)
        }
    }
}
