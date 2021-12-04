//
//  AddAbstractView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/20/21.
//

import SwiftUI

struct EditAbstractView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    var article: Article
    @State var abstract: String
    @State private var enableSaveButton = false
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            TextEditor(text: $abstract)
                .onChange(of: abstract, perform: { _ in
                    enableSaveButton = true
                })
                .disableAutocorrection(true)
                .multilineTextAlignment(.leading)
                .border(Color.secondary)
            
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
    }
    
    private func header() -> some View {
        ZStack {
            HStack {
                Spacer()
                Text("Edit Abstract")
                Spacer()
            }
            
            HStack {
                Button {
                    dismiss.callAsFunction()
                } label: {
                    Text("Cancel")
                }
                
                Spacer()
                
                Button {
                    update()
                    dismiss.callAsFunction()
                } label: {
                    Text("Save")
                }
                .disabled(!enableSaveButton)
            }
        }
    }
    
    private func update() -> Void {
        article.abstract = abstract
        
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
