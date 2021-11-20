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
    
    var body: some View {
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
                        Text(article.title ?? "")
                    }
                }
                .onMove(perform: move)
            }
            
            Divider()
            
            List {
                ForEach(articles) { article in
                    Button {
                        if articlesToAdd.contains(article) {
                            if let index = articlesToAdd.firstIndex(of: article) {
                                articlesToAdd.remove(at: index)
                            }
                        } else {
                            articlesToAdd.append(article)
                        }
                    } label: {
                        Text(article.title ?? "")
                    }
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
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
    
    private func addNewCollection() -> Void {
        let date = Date()
        
        let collection = Collection(context: viewContext)
        collection.name = name
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
