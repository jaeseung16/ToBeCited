//
//  AuthorDetailView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/19/21.
//

import SwiftUI
import CoreData

struct AuthorDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @State var author: Author
    @State var firstName: String
    @State var middleName: String
    @State var lastName: String
    @State var nameSuffix: String
    @State var orcid: String
    
    private var contacts: [AuthorContact] {
        author.contacts?.filter { $0 is AuthorContact }.map { $0 as! AuthorContact } ?? [AuthorContact]()
    }
    
    @State private var presentAuthorMergeView = false
    @State private var presentAddContactView = false
    @State private var editLastName = false
    @State private var editFirstName = false
    @State private var editMiddleName = false
    @State private var cancelled = false
    @State private var presentAddToCollectionsView = false
    
    private var articles: [Article] {
        var articles = [Article]()
        author.articles?.forEach { article in
            if let article = article as? Article {
                articles.append(article)
            }
        }
        return articles.sorted {
            if let date1 = $0.published, let date2 = $1.published {
                return date1 > date2
            } else {
                return false
            }
        }
    }
    
    private var authors: [Author] {
        if let lastName = author.lastName, let firstLetterOfFirstName = author.firstName?.first {
            let predicate = NSPredicate(format: "(lastName CONTAINS[cd] %@) AND (firstName BEGINSWITH[cd] %@)", argumentArray: [lastName, firstLetterOfFirstName.lowercased()])
            let sortDesciptor = NSSortDescriptor(key: "firstName", ascending: true)
            
            let fetchRequest: NSFetchRequest<Author> = Author.fetchRequest()
            fetchRequest.predicate = predicate
            fetchRequest.sortDescriptors = [sortDesciptor]
            
            let fc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)
            
            do {
                try fc.performFetch()
            } catch {
                NSLog("Failed fetch authors with lastName = \(lastName)")
            }
            
            return fc.fetchedObjects ?? [Author]()
        }
        
        return [Author]()
    }
    
    private var orcidURL: URL? {
        if let orcid = author.orcid, let url = URL(string: "https://orcid.org/\(orcid)") {
            return url
        } else {
            return nil
        }
    }
    
    var body: some View {
        ScrollView {
            VStack {
                header()
                
                Divider()
                
                name(author: author)
                
                HStack {
                    Text("ORCID")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 90, alignment: .leading)
                    
                    Spacer()
                        .frame(width: 20)
                    
                    TextField("orcid", text: $orcid, prompt: nil)
                        .onSubmit {
                            author.orcid = orcid
                            viewModel.save(viewContext: viewContext)
                        }
                    
                    if let orcidURL = orcidURL {
                        Link(destination: orcidURL) {
                            Label("ORCiD", systemImage: "link")
                        }
                    }
                }
                
                Divider()
                
                contactsView()
                    .frame(height: 200)
                
                Divider()
                
                articlesView()
                    .frame(height: 400)
            }
            .navigationTitle(viewModel.nameComponents(of: author).formatted(.name(style: .long)))
            .frame(maxHeight: .infinity, alignment: .top)
            .padding()
            .sheet(isPresented: $presentAuthorMergeView) {
                AuthorMergeView(authors: authors)
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $presentAddContactView) {
                AddContactView(author: author)
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $presentAddToCollectionsView) {
                AddAuthorToCollectionView(articles: articles)
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(viewModel)
            }
        }
    }
    
    private func header() -> some View {
        HStack {
            Spacer()
            
            Button {
                presentAddContactView = true
            } label: {
                Label("ADD CONTACT", systemImage: "plus")
            }
            
            Button {
                presentAuthorMergeView = true
            } label: {
                Label("MERGE AUTHORS", systemImage: "arrow.triangle.merge")
            }
        }
    }
    
    private func name(author: Author) -> some View {
        VStack {
            HStack {
                Text("LAST NAME")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 90, alignment: .leading)
                
                Spacer()
                    .frame(width: 20)
                
                TextField("last name", text: $lastName, prompt: nil)
                    .onSubmit {
                        author.lastName = lastName
                        viewModel.save(viewContext: viewContext)
                    }
            }
            
            HStack {
                Text("FIRST NAME")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 90, alignment: .leading)
                
                Spacer()
                    .frame(width: 20)
                
                TextField("fist name", text: $firstName, prompt: nil)
                    .onSubmit {
                        author.firstName = firstName
                        viewModel.save(viewContext: viewContext)
                    }
            }
            
            HStack {
                Text("MIDDLE NAME")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 90, alignment: .leading)
                
                Spacer()
                    .frame(width: 20)
                
                TextField("middle name", text: $middleName, prompt: nil)
                    .onSubmit {
                        author.middleName = middleName
                        viewModel.save(viewContext: viewContext)
                    }
            }
            
            HStack {
                Text("SUFFIX")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 90, alignment: .leading)
                
                Spacer()
                    .frame(width: 20)
                
                TextField("suffix", text: $nameSuffix, prompt: nil)
                    .onSubmit {
                        author.nameSuffix = nameSuffix
                        viewModel.save(viewContext: viewContext)
                    }
            }
            
        }
    }
    
    private func contactsView() -> some View {
        VStack {
            HStack {
                Text("CONTACT INFORMATION: \(contacts.count) CONTACTS")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            List {
                ForEach(contacts) { contact in
                    AuthorContactView(contact: contact, email: contact.email ?? "", institution: contact.institution ?? "", address: contact.address ?? "")
                }
                .onDelete(perform: deleteContact)
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private func articlesView() -> some View {
        VStack {
            HStack {
                Text("\(author.articles?.count ?? 0) ARTICLES")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    presentAddToCollectionsView = true
                } label: {
                    Text("Add to existing collections")
                }
            }
            
            List {
                ForEach(articles) { article in
                    NavigationLink {
                        ArticleSummaryView(article: article)
                    } label: {
                        ArticleRowView(article: article)
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private func name(of author: Author) -> String {
        guard let lastName = author.lastName, let firstName = author.firstName else {
            return "The name of an author is not available"
        }
        
        let middleName = author.middleName == nil ? " " : " \(author.middleName!) "
        
        return firstName + middleName + lastName
    }
    
    private func deleteContact(_ indexSet: IndexSet) -> Void {
        withAnimation {
            viewModel.delete( indexSet.map { contacts[$0] }, from: author, viewContext: viewContext)
        }
    }
}
