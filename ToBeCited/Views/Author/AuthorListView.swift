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
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Author.lastName, ascending: true)],
        animation: .default)
    private var authors: FetchedResults<Author>

    var body: some View {
        NavigationView {
            List {
                ForEach(authors) { author in
                    NavigationLink(destination: AuthorDetailView(author: author, contacts: getContacts(of: author))) {
                        HStack {
                            Text(viewModel.nameComponents(of: author).formatted(.name(style: .long)))
                            Spacer()
                        }
                    }
                }
                .onDelete(perform: deleteAuthors)
            }
            .navigationTitle("Authors")
        }
    }
    
    private func getContacts(of author: Author) -> [AuthorContact] {
        let predicate = NSPredicate(format: "author == %@", argumentArray: [author])
        let sortDescriptor = NSSortDescriptor(keyPath: \AuthorContact.created, ascending: false)
        
        let fetchRequest = NSFetchRequest<AuthorContact>(entityName: "AuthorContact")
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = predicate
        
        let fc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fc.performFetch()
        } catch {
            NSLog("Failed fetch contacts with author = \(author)")
        }
        
        return fc.fetchedObjects ?? [AuthorContact]()
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
