//
//  AuthorDetailView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/19/21.
//

import SwiftUI

struct AuthorDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    var author: Author
    
    @State private var presentAuthorMergeView = false
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
        VStack {
            header()
            
            Divider()
            
            name(author: author)
            
            Divider()
            
            HStack {
                Text("\(author.articles?.count ?? 0) ARTICLES")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            List {
                ForEach(articles) { article in
                    Text(article.title ?? "")
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
        .sheet(isPresented: $presentAuthorMergeView) {
            AuthorMergeView(authors: authors)
        }

    }
    
    private func header() -> some View {
        HStack {
            Spacer()
            
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
                save()
            }
        } content: {
            UpdateTextView(title: "Edit the author's last name", textToUpdate: $lastName, cancelled: $cancelled)
        }
        .sheet(isPresented: $editFirstName) {
            if !cancelled {
                author.firstName = firstName
                save()
            }
        } content: {
            UpdateTextView(title: "Edit the author's first name", textToUpdate: $firstName, cancelled: $cancelled)
        }
        .sheet(isPresented: $editMiddleName) {
            if !cancelled {
                author.middleName = middleName
                save()
            }
        } content: {
            UpdateTextView(title: "Edit the author's middle name", textToUpdate: $middleName, cancelled: $cancelled)
        }

    }
    
    func save() -> Void {
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
}
