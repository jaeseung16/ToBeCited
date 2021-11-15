//
//  EditCollectionView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/14/21.
//

import SwiftUI

struct EditCollectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Article.published, ascending: false)],
        animation: .default)
    private var articles: FetchedResults<Article>
    
    var collection: Collection
    
    @State var articlesInCollection: [Article]
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            List {
                ForEach(articlesInCollection) { article in
                    Button {
                        if let index = articlesInCollection.firstIndex(of: article) {
                            articlesInCollection.remove(at: index)
                        }
                    } label: {
                        HStack {
                            Text(article.title ?? "")
                        }
                    }                    
                }
            }
            
            Divider()
            
            List {
                ForEach(articles) { article in
                    Button {
                        if articlesInCollection.contains(article) {
                            if let index = articlesInCollection.firstIndex(of: article) {
                                articlesInCollection.remove(at: index)
                            }
                        } else {
                            articlesInCollection.append(article)
                        }
                    } label: {
                        HStack {
                            Text(article.title ?? "")
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    private func header() -> some View {
        HStack {
            Spacer()
            
            Button {
                viewContext.rollback()
                
                dismiss.callAsFunction()
            } label: {
                Text("Cancel")
            }
            
            Spacer()
            
            Button {
                collection.orders?.forEach { order in
                    if let order = order as? OrderInCollection {
                        //collection.removeFromOrders(order)
                        //order.article = nil
                        viewContext.delete(order)
                    }
                }
                
                collection.articles?.forEach { article in
                    if let article = article as? Article {
                        article.removeFromCollections(collection)
                    }
                }
                
                for index in 0..<articlesInCollection.count {
                    let article = articlesInCollection[index]
                    article.addToCollections(collection)
                    
                    let order = OrderInCollection(context: viewContext)
                    order.collectionId = collection.uuid
                    order.articleId = article.uuid
                    order.order = Int64(index)
                    collection.addToOrders(order)
                    article.addToOrders(order)
                }
                
                viewModel.save(viewContext: viewContext)
                
                dismiss.callAsFunction()
            } label: {
                Text("Save")
            }

            Spacer()
        }
    }

}

