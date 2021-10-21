//
//  AddRISView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/18/21.
//

import SwiftUI

struct AddRISView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var presentRISFilePicker = false
    @State private var risString: String = ""
    @State private var risRecords = [RISRecord]()
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            Text(risString)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
        .sheet(isPresented: $presentRISFilePicker) {
            RISFilePickerViewController(risString: $risString)
        }
        .onChange(of: presentRISFilePicker) { _ in
            if !presentRISFilePicker {
                let parser = RISParser()
                let records = try? parser.parse(risString)
                
                if records != nil {
                    print("records.count = \(records!.count)")
                    
                    for record in records! {
                        self.risRecords.append(record)
                    }
                }
            }
        }
    }
    
    private func header() -> some View {
        ZStack {
            HStack {
                Spacer()
                
                Button {
                    presentRISFilePicker = true
                } label: {
                    Text("Select a RIS file")
                }
                
                Spacer()
            }
            
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("Cancel")
                })
                
                Spacer()
                
                Button(action: {
                    addNewArticle()
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("Save")
                })
            }
        }
    }
    
    private func addNewArticle() {
        let created = Date()
        
        for record in risRecords {
            let newArticle = Article(context: viewContext)
            newArticle.created = created
            newArticle.title = record.primaryTitle ?? record.title
            newArticle.journal = record.periodicalNameFullFormat
            newArticle.abstract = record.abstract
            newArticle.doi = record.doi
            newArticle.volume = record.volumeNumber
            newArticle.issueNumber = record.issueNumber
            newArticle.page = record.startPage
            
            if let primaryAuthor = record.primaryAuthor {
                createAuthorEntity(primaryAuthor, article: newArticle)
            }
            
            if let secondaryAuthor = record.secondaryAuthor {
                createAuthorEntity(secondaryAuthor, article: newArticle)
            }
            
            if let tertiaryAuthor = record.tertiaryAuthor {
                createAuthorEntity(tertiaryAuthor, article: newArticle)
            }
            if let subsidiaryAuthor = record.subsidiaryAuthor {
                createAuthorEntity(subsidiaryAuthor, article: newArticle)
            }
            
            for author in record.authors {
                createAuthorEntity(author, article: newArticle)
            }
            
            let writer = RISWriter(record: record)
            let ris = RIS(context: viewContext)
            ris.uuid = UUID()
            ris.content = writer.toString()
            ris.article = newArticle
            
        }
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        risRecords.removeAll()
    }
    
    private func createAuthorEntity(_ authorName: String, article: Article) -> Void {
        let authorEntity = Author(context: viewContext)
        authorEntity.created = Date()
        authorEntity.uuid = UUID()
        
        let name = authorName.split(separator: ",")
        
        authorEntity.lastName = String(name[0])
        
        if name.count > 1 {
            let firstMiddleName = String(name[1]).split(separator: " ")
            
            authorEntity.firstName = String(firstMiddleName[0])
            if firstMiddleName.count > 1 {
                authorEntity.middleName = String(firstMiddleName[1])
            }
        }
        
        authorEntity.addToArticles(article)
    }
}

struct AddRISView_Previews: PreviewProvider {
    static var previews: some View {
        AddRISView()
    }
}
