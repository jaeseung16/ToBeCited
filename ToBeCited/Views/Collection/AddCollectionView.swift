//
//  AddCollectionView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/10/21.
//

import SwiftUI

struct AddCollectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Article.published, ascending: false)],
        animation: .default)
    private var articles: FetchedResults<Article>
    
    @State private var name: String = ""
    @State private var articlesToAdd = [Article]()
    
    @State var selectedAuthor: Author?
    
    private var filteredArticles: Array<Article> {
        articles.filter { article in
            if let authors = article.authors as? Set<Author>, let author = selectedAuthor {
                return authors.contains(author)
            }
            return false
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                HStack {
                    Text("NAME")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Collection Name", text: $name, prompt: nil)
                }
                
                List {
                    ForEach(articlesToAdd) { article in
                        Button {
                            if let index = articlesToAdd.firstIndex(of: article) {
                                articlesToAdd.remove(at: index)
                            }
                        } label: {
                            ArticleRowView(article: article)
                        }
                    }
                    .onMove(perform: move)
                }
                
                Divider()
                
                authorsView()
                    .frame(height: 0.25 * geometry.size.height)
                
                Divider()
                
                List {
                    ForEach(filteredArticles) { article in
                        Button {
                            if articlesToAdd.contains(article) {
                                if let index = articlesToAdd.firstIndex(of: article) {
                                    articlesToAdd.remove(at: index)
                                }
                            } else {
                                articlesToAdd.append(article)
                            }
                        } label: {
                            ArticleRowView(article: article)
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding()
        }
    }
    
    private func header() -> some View {
        ZStack {
            HStack {
                Spacer()
                Text("Add an article")
                Spacer()
            }
            
            HStack {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Cancel")
                }

                Spacer()
                
                Button(action: {
                    addNewCollection()
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("Save")
                })
            }
        }
    }
    
    private func authorsView() -> some View {
        VStack {
            Text("CHOOSE AN AUTHOR")
                .font(.callout)
            
            List {
                ForEach(authors) { author in
                    Button {
                        selectedAuthor = author
                    } label: {
                        HStack {
                            Text(author.firstName ?? "")
                            
                            Text(author.lastName ?? "")
                            
                            Spacer()
                            
                            Text("\(author.articles?.count ?? 0)")
                        }
                    }
                    .foregroundColor(author == selectedAuthor ? .primary : .secondary)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        return dateFormatter
    }
    
    private func addNewCollection() -> Void {
        let date = Date()
        
        let collection = Collection(context: viewContext)
        collection.name = name != "" ? name : dateFormatter.string(from: date)
        collection.uuid = UUID()
        collection.created = date
        collection.lastupd = date
        
        for index in 0..<articlesToAdd.count {
            collection.addToArticles(articlesToAdd[index])
            
            let orderInCollection = OrderInCollection(context: viewContext)
            orderInCollection.collectionId = collection.uuid
            orderInCollection.articleId = articlesToAdd[index].uuid
            orderInCollection.order = Int64(index)
            orderInCollection.collection = collection
            orderInCollection.article = articlesToAdd[index]
            
            //collection.addToOrders(orderInCollection)
        }
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func move(from source: IndexSet, to destination: Int) {
        articlesToAdd.move(fromOffsets: source, toOffset: destination)
    }
}
