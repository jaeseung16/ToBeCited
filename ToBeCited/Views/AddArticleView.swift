//
//  AddArticleView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/17/21.
//

import SwiftUI

struct AddArticleView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var title: String = ""
    
    @State private var journal: String = ""
    @State private var volume: String = ""
    @State private var number: String = ""
    @State private var pages: String = ""
    
    @State private var published: Date = Date()
    
    @State private var doi: String = ""
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            titleView()
            
            journalView()
            
            DatePicker("PUBLISHED", selection: $published, displayedComponents: [.date])

            doiView()
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
                
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Save")
                }
            }
        }
    }
    
    private func titleView() -> some View {
        VStack(alignment: .leading) {
            Text("TITLE")
            TextField("Title", text: $title)
                .multilineTextAlignment(.trailing)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
        }
    }
    
    private func journalView() -> some View {
        VStack(alignment: .leading) {
            Text("JOURNAL")
            TextField("journal", text: $title)
                .multilineTextAlignment(.trailing)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            
            Text("VOLUME")
            TextField("volume", text: $title)
                .multilineTextAlignment(.trailing)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            
            Text("NUMBER")
            TextField("number", text: $title)
                .multilineTextAlignment(.trailing)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            
            Text("PAGES")
            TextField("pages", text: $title)
                .multilineTextAlignment(.trailing)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
        }
    }
    
    private func doiView() -> some View {
        VStack(alignment: .leading) {
            Text("DOI")
            TextField("doi", text: $doi)
                .multilineTextAlignment(.trailing)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
        }
    }
    
    private func addItem() {
        let newItem = Item(context: viewContext)
        newItem.timestamp = Date()
        
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

struct AddArticleView_Previews: PreviewProvider {
    static var previews: some View {
        AddArticleView()
    }
}
