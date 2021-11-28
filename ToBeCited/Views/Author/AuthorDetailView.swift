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
    
    var contacts: [AuthorContact] {
        author.contacts?.filter { $0 is AuthorContact } as! [AuthorContact]
    }
    
    @State private var presentAuthorMergeView = false
    @State private var presentAddContactView = false
    @State private var editLastName = false
    @State private var editFirstName = false
    @State private var editMiddleName = false
    
    @State private var lastName = ""
    @State private var firstName = ""
    @State private var middleName = ""
    
    @State private var cancelled = false
    
    private var articles: [Article] {
        var articles = [Article]()
        author.articles?.forEach { article in
            if let article = article as? Article {
                articles.append(article)
            }
        }
        return articles
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
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                name(author: author)
                
                Divider()
                
                contactsView()
                    .frame(height: 0.25 * geometry.size.height)
                
                Divider()
                
                articlesView()
                    .frame(height: 0.45 * geometry.size.height)
            }
            .navigationTitle(viewModel.nameComponents(of: author).formatted(.name(style: .long)))
            .frame(maxHeight: .infinity, alignment: .top)
            .padding()
            .sheet(isPresented: $presentAuthorMergeView) {
                AuthorMergeView(authors: authors)
            }
            .sheet(isPresented: $presentAddContactView) {
                AddContactView(author: $author)
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
                
                Spacer()
                
                Text(author.lastName ?? "")
                
                Spacer()
                
                Button {
                    lastName = author.lastName ?? ""
                    editLastName = true
                } label: {
                    Label("Edit", systemImage: "pencil.circle")
                }
            }
            
            HStack {
                Text("FIRST NAME")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(author.firstName ?? "")
                
                Spacer()
                
                Button {
                    firstName = author.firstName ?? ""
                    editFirstName = true
                } label: {
                    Label("Edit", systemImage: "pencil.circle")
                }
            }
            
            HStack {
                Text("MIDDLE NAME")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(author.middleName ?? "")
                
                Spacer()
                
                Button {
                    middleName = author.middleName ?? ""
                    editMiddleName = true
                } label: {
                    Label("Edit", systemImage: "pencil.circle")
                }
            }
            
        }
        .sheet(isPresented: $editLastName) {
            if !cancelled {
                author.lastName = lastName
                saveViewContext()
            }
        } content: {
            UpdateTextView(title: "Edit the author's last name", textToUpdate: $lastName, cancelled: $cancelled)
        }
        .sheet(isPresented: $editFirstName) {
            if !cancelled {
                author.firstName = firstName
                saveViewContext()
            }
        } content: {
            UpdateTextView(title: "Edit the author's first name", textToUpdate: $firstName, cancelled: $cancelled)
        }
        .sheet(isPresented: $editMiddleName) {
            if !cancelled {
                author.middleName = middleName
                saveViewContext()
            }
        } content: {
            UpdateTextView(title: "Edit the author's middle name", textToUpdate: $middleName, cancelled: $cancelled)
        }
    }
    
    func saveViewContext() -> Void {
        viewModel.save(viewContext: viewContext)
    }
    
    private func contactsView() -> some View {
        VStack {
            HStack {
                Text("CONTACT INFORMATION")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            List {
                ForEach(contacts) { contact in
                    HStack {
                        Spacer()
                        VStack {
                            Text(contact.email ?? "")
                            Text(contact.institution ?? "")
                            Text(contact.address ?? "")
                            Text("Added on \(dateFormatter.string(from: contact.created ?? Date()))")
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                   
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
            }
            
            List {
                ForEach(articles) { article in
                    NavigationLink {
                        ArticleSummaryView(article: article)
                    } label: {
                        VStack {
                            HStack {
                                Text(article.title ?? "N/A")
                                Spacer()
                            }
                            
                            HStack {
                                Spacer()
                                Text(article.journal ?? "N/A")
                                    .font(.callout)
                                    .foregroundColor(.secondary)
                                Spacer()
                                    .frame(width: 20)
                                Text("\(viewModel.yearOnlyDateFormatter.string(from: article.published ?? Date()))")
                                    .font(.callout)
                                    .foregroundColor(.secondary)
                            }
                        }
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
    
    private var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter
    }
    
    private func deleteContact(_ indexSet: IndexSet) -> Void {
        withAnimation {
            indexSet.forEach { index in
                let contact = contacts[index]
                author.removeFromContacts(contact)
                viewContext.delete(contact)
                saveViewContext()
            }
        }
    }
}
