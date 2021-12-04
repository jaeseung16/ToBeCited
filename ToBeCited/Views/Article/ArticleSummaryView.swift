//
//  ArticleSummaryView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/28/21.
//

import SwiftUI

struct ArticleSummaryView: View {
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @State var article: Article
    
    private var authors: [Author] {
        var authors = [Author]()
        article.authors?.forEach { author in
            if let author = author as? Author {
                authors.append(author)
            }
        }
        return authors
    }
    
    private var abstractExists: Bool {
        if let abstract = article.abstract {
            return !abstract.isEmpty
        } else {
            return false
        }
    }
    
    var body: some View {
        ScrollView {
            VStack {
                citation()
                
                Divider()
                
                abstractView()
            }
        }
        .navigationTitle(article.title ?? "Title is not available")
        .padding()
    }
    
    private func citation() -> some View {
        VStack {
            Text(article.title ?? "Title is not available")
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
            
            Text(journalString)
            
            if article.published != nil {
                Text(publicationDate)
                    .font(.callout)
            }
            
            if article.doi != nil, let url = URL(string: "https://dx.doi.org/\(article.doi!)") {
                Link(article.doi!, destination: url)
                    .foregroundColor(.blue)
            }
            
            authorList()
        }
    }
    
    private var journalString: String {
        guard let journalTitle = article.journal else {
            return "Journal title is not available"
        }
        
        return journalTitle + " " + (article.volume ?? "") + ", " + (article.page ?? "")
    }
    
    private var publicationDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: article.published!)
    }
    
    private func authorList() -> some View {
        VStack {
            HStack {
                Text("AUTHORS (unordered)")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            ForEach(authors, id: \.uuid) { author in
                HStack {
                    Spacer()
                    Text(viewModel.nameComponents(of: author).formatted(.name(style: .long)))
                    Spacer()
                }
            }
        }
    }
    
    private func name(of author: Author) -> String {
        guard let lastName = author.lastName, let firstName = author.firstName else {
            return "The name of an author is not available"
        }
        
        let middleName = author.middleName == nil ? " " : " \(author.middleName!) "
        
        return firstName + middleName + lastName
    }
    
    private func abstractView() -> some View {
        VStack {
            HStack {
                Text("ABSTRACT")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            if abstractExists {
                Text(article.abstract!)
                    .padding()
            } else {
                Text("No Abstract")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
    
}
