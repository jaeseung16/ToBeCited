//
//  SelectArticlesView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/10/21.
//

import SwiftUI

struct SelectReferencesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State var article: Article
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Article.published, ascending: false)],
        animation: .default)
    private var articles: FetchedResults<Article>
    
    private var references: [Article] {
        var references = [Article]()
        article.references?.forEach { reference in
            if let reference = reference as? Article {
                references.append(reference)
            }
        }
        return references
    }
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            List {
                ForEach(references) { reference in
                    Button {
                        self.article.removeFromReferences(reference)
                        
                        reference.removeFromCited(self.article)
                        
                        do {
                            try viewContext.save()
                        } catch {
                            // Replace this implementation with code to handle the error appropriately.
                            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                            let nsError = error as NSError
                            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                        }
                        
                        print("selected \(article.references)")
                        
                    } label: {
                        Text(reference.title ?? "")
                    }
                }
            }
            
            Divider()
            
            List {
                ForEach(articles) { reference in
                    Button {
                        self.article.addToReferences(reference)
                        
                        reference.addToCited(self.article)
                        
                        do {
                            try viewContext.save()
                        } catch {
                            // Replace this implementation with code to handle the error appropriately.
                            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                            let nsError = error as NSError
                            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                        }
                        
                        print("selected \(article.references)")
                        
                    } label: {
                        Text(reference.title ?? "")
                    }
                }
            }
        }
        .navigationTitle(article.title ?? "No Title")
        .padding()
    }
    
    private func header() -> some View {
        HStack {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text("Dismiss")
            }
            
            Spacer()
            
            Button {
                update()
            } label: {
                Text("Save")
            }
        }
    }
    
    private func update() -> Void {
        
    }
}
