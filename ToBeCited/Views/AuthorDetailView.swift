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
        if let lastName = author.lastName {
            let predicate = NSPredicate(format: "lastName == %@", argumentArray: [lastName])
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
            
            Text("NUMBER OF ARTICLES")
            Text("\(author.articles?.count ?? 0)")
            
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
                Text("Merge")
            }

        }
    }
    
    private func name(author: Author) -> some View {
        VStack {
            Text("LAST NAME")
            Text(author.lastName ?? "")
            
            Text("FIRST NAME")
            Text(author.firstName ?? "")
            
            Text("MIDDLE NAME")
            Text(author.middleName ?? "")
        }
    }
    
    
}
