//
//  AuthorMergeView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/21/21.
//

import SwiftUI

struct AuthorMergeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    var authors: [Author]
    
    @State private var selected: [Author] = [Author]()
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            List {
                ForEach(selected) { author in
                    name(author: author)
                }
            }
            Divider()
            
            List {
                ForEach(authors) { author in
                    Button {
                        if selected.contains(author), let index = selected.firstIndex(of: author) {
                            selected.remove(at: index)
                        } else {
                            selected.append(author)
                        }
                    } label: {
                        name(author: author)
                    }
                }
            }
        }
        .padding()
    }
    
    private func header() -> some View {
        HStack {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text("Done")
            }
            
            Spacer()
            
            Button {
                merge()
            } label: {
                Text("Perform merge")
            }
            .disabled(selected.count < 2)

        }
    }
    
    private func name(author: Author) -> some View {
        HStack {
            Text(author.lastName ?? "")
            Spacer()
            Text(author.firstName ?? "")
            Spacer()
            Text(author.middleName ?? "")
        }
    }
    
    private func merge() -> Void {
        let merged = selected[0]
        
        for index in 1..<selected.count {
            selected[index].articles?.forEach({ article in
                if let article = article as? Article {
                    merged.addToArticles(article)
                    selected[index].removeFromArticles(article)
                }
            })
            
            viewContext.delete(selected[index])
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
}


