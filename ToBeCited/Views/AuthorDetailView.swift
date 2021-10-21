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
    
    private var articles: [Article] {
        var articles = [Article]()
        author.articles?.forEach { article in
            if let article = article as? Article {
                articles.append(article)
            }
        }
        return articles
    }
    
    var body: some View {
        VStack {
            Text("LAST NAME")
            Text(author.lastName ?? "")
            
            Text("FIRST NAME")
            Text(author.firstName ?? "")
            
            Text("MIDDLE NAME")
            Text(author.middleName ?? "")
            
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
    }
}
