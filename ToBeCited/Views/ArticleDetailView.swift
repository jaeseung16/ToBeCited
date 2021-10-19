//
//  ArticleDetailView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/19/21.
//

import SwiftUI

struct ArticleDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    var article: Article
    
    private var authors: [Author] {
        var authors = [Author]()
        article.authors?.forEach { author in
            if let author = author as? Author {
                authors.append(author)
            }
        }
        return authors
    }
    
    var body: some View {
        VStack {
            Text(article.title ?? "title")
            
            Text(article.journal ?? "journal")
            
            Text(article.abstract ?? "abstract")
            
            List {
                ForEach(authors, id: \.uuid) { author in
                    HStack {
                        Text(author.lastName ?? "last name")
                        Spacer()
                        Text(author.firstName ?? "first name")
                        Spacer()
                        Text(author.middleName ?? "middle name")
                    }
                }
            }
        }
    }
}

