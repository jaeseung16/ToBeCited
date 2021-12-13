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

    var body: some View {
        NavigationView {
            List {
                ForEach(authors) { author in
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
                .onDelete(perform: deleteAuthors)
            }
            .navigationTitle("Authors")
        }
    }
    
    private func deleteAuthors(offsets: IndexSet) {
        withAnimation {
            offsets.map { authors[$0] }.forEach { author in
                if author.articles == nil || author.articles!.count == 0 {
                    viewContext.delete(author)
                }
            }
            viewModel.save(viewContext: viewContext)
        }
    }
}
