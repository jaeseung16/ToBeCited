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
    @Environment(\.managedObjectContext) private var viewContext
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
            .searchable(text: $viewModel.authorSearchString)
            .searchSuggestions({
                ForEach($viewModel.authorSuggestions, id: \.self) { suggestion in
                    Text(suggestion.wrappedValue)
                        .searchCompletion(suggestion.wrappedValue)
                }
            })
            .navigationTitle(Text("Authors"))
            .refreshable {
                viewModel.fetchAll()
            }
        } detail: {
            if let author = selectedAuthor {
                AuthorDetailView(author: author,
                                 firstName: author.firstName ?? "",
                                 middleName: author.middleName ?? "",
                                 lastName: author.lastName ?? "",
                                 nameSuffix: author.nameSuffix ?? "",
                                 orcid: author.orcid ?? "")
                .id(author)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(viewModel)
            }
        }
        .onContinueUserActivity(CSSearchableItemActionType) { activity in
            Task(priority: .userInitiated) {
                if let author = await viewModel.continueActivity(activity) as? Author {
                    viewModel.authorSearchString = ToBeCitedNameFormatHelper.formatName(of: author)
                    selectedAuthor = author
                }
            }
        }
        .onAppear() {
            if viewModel.selectedTab != .authors {
                viewModel.selectedTab = .authors
            }
        }
    }
    
    private func deleteAuthors(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { viewModel.authors[$0] } )
            selectedAuthor = nil
        }
    }
}
