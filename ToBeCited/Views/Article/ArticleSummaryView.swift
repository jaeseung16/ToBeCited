//
//  ArticleSummaryView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/28/21.
//

import SwiftUI

struct ArticleSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State var article: Article
    
    private var authors: [Author] {
        return article.authors?.compactMap { $0 as? Author } ?? [Author]()
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
            
            JournalTitleView(article: article)
            
            if article.published != nil {
                publishedView()
            }
            
            if let doi = article.doi, let url = URL(string: "https://dx.doi.org/\(doi)") {
                linkView(for: doi, url: url)
            }
            
            authorList()
        }
    }
    
    private var publicationDate: String {
        return ToBeCitedDateFormatter.publication.string(from: article.published!)
    }
    
    private func publishedView() -> some View {
        ZStack {
            HStack {
                if UIDevice.current.userInterfaceIdiom != .phone {
                    Label("PUBLISHED ON", systemImage: "calendar")
                        .font(.callout)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "calendar")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            Text(publicationDate)
                .font(.callout)
        }
    }
    
    private func linkView(for doi: String, url: URL) -> some View {
        ZStack {
            HStack {
                if UIDevice.current.userInterfaceIdiom != .phone {
                    Label("DOI LINK", systemImage: "link")
                        .font(.callout)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "link")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Link(doi, destination: url)
                .foregroundColor(.blue)
        }
    }
    
    private func authorList() -> some View {
        VStack {
            HStack {
                Label("AUTHORS (unordered)", systemImage: "person.3")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            ForEach(authors, id: \.uuid) { author in
                HStack {
                    Spacer()
                    AuthorNameView(author: author)
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

