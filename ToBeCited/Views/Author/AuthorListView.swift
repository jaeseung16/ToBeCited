//
//  AuthorListView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/28/21.
//

import SwiftUI
import CoreData
import CoreSpotlight

struct AuthorListView: View {
    @EnvironmentObject private var viewModel: ToBeCitedViewModel

    @State private var selectedAuthor: Author?
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedAuthor) {
                ForEach(viewModel.authors) { author in
                    NavigationLink(value: author) {
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
            .searchable(text: $viewModel.authorSearchString)
        } detail: {
            if let author = selectedAuthor {
                AuthorDetailView(author: author,
                                 firstName: author.firstName ?? "",
                                 middleName: author.middleName ?? "",
                                 lastName: author.lastName ?? "",
                                 nameSuffix: author.nameSuffix ?? "",
                                 orcid: author.orcid ?? "")
                .id(author)
            }
        }
        .onChange(of: viewModel.authorSearchString) {
            viewModel.searchAuthor()
        }
        .onContinueUserActivity(CSSearchableItemActionType) { activity in
            viewModel.continueActivity(activity) { entity in
                if let author = entity as? Author {
                    viewModel.authorSearchString = ToBeCitedNameFormatHelper.formatName(of: author)
                    selectedAuthor = author
                }
            }
        }
    }
    
    private func deleteAuthors(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { viewModel.authors[$0] } )
        }
    }
}
