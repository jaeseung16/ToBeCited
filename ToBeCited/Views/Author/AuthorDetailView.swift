//
//  AuthorDetailView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/19/21.
//

import SwiftUI
import CoreData

struct AuthorDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
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
        let articles = author.articles?.compactMap { $0 as? Article} ?? [Article]()
        return articles.sorted {
            if let date1 = $0.published, let date2 = $1.published {
                return date1 > date2
            } else {
                return false
            }
        }
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
                            viewContext.perform {
                                author.orcid = orcid
                                
                                Task {
                                    do {
                                        try await viewModel.save()
                                    } catch {
                                        viewModel.log("Failed to save last name: \(error.localizedDescription)")
                                    }
                                }
                            }
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
            .navigationTitle(ToBeCitedNameFormatHelper.formatName(of: author))
            .frame(maxHeight: .infinity, alignment: .top)
            .padding()
            .sheet(isPresented: $presentAuthorMergeView) {
                AuthorMergeView(authors: viewModel.findAuthors(by: author))
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $presentAddContactView) {
                AddContactView(author: author)
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $presentAddToCollectionsView) {
                AddAuthorToCollectionView(articles: articles)
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
                        viewContext.perform {
                            author.lastName = lastName
                            
                            Task {
                                do {
                                    try await viewModel.save()
                                } catch {
                                    viewModel.log("Failed to save last name: \(error.localizedDescription)")
                                }
                            }
                        }
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
                        viewContext.perform {
                            author.firstName = firstName
                            
                            Task {
                                do {
                                    try await viewModel.save()
                                } catch {
                                    viewModel.log("Failed to save first name: \(error.localizedDescription)")
                                }
                            }
                        }
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
                        viewContext.perform {
                            author.middleName = middleName
                            
                            Task {
                                do {
                                    try await viewModel.save()
                                } catch {
                                    viewModel.log("Failed to save middle name: \(error.localizedDescription)")
                                }
                            }
                        }
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
                        viewContext.perform {
                            author.nameSuffix = nameSuffix
                            
                            Task {
                                do {
                                    try await viewModel.save()
                                } catch {
                                    viewModel.log("Failed to save name suffix: \(error.localizedDescription)")
                                }
                            }
                        }
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
                        .environment(\.managedObjectContext, viewContext)
                        .environmentObject(viewModel)
                }
                .onDelete(perform: deleteContact)
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private func articlesView() -> some View {
        VStack {
            HStack {
                Label("ARTICLES (\(author.articles?.count ?? 0))", systemImage: "doc.on.doc")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    presentAddToCollectionsView = true
                } label: {
                    Text("Add to existing collections")
                }
            }
            
            NavigationStack {
                List {
                    ForEach(articles) { article in
                        NavigationLink(value: article) {
                            ArticleRowView(article: article)
                        }
                    }
                }
                .navigationDestination(for: Article.self) { article in
                    ArticleSummaryView(article: article)
                }
                .listStyle(PlainListStyle())
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
    
    private func deleteContact(_ indexSet: IndexSet) -> Void {
        withAnimation {
            viewModel.delete( indexSet.map { contacts[$0] }, from: author)
        }
    }
}
