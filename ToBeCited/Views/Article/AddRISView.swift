//
//  AddRISView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/18/21.
//

import SwiftUI
import UniformTypeIdentifiers

struct AddRISView: View, DropDelegate {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @State private var presentRISFilePicker = false
    @State private var risString: String = ""
    @State private var risRecords = [RISRecord]()
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                if risString.isEmpty {
                    Image(systemName: "doc.text")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 0.2 * geometry.size.width)
                        .onDrop(of: [RISFilePickerViewController.risUTType, .text], delegate: self)
                } else {
                    Text(risString)
                }
                
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding()
            .sheet(isPresented: $presentRISFilePicker) {
                RISFilePickerViewController(risString: $risString)
            }
            .onChange(of: risString) { _ in
                if !risString.isEmpty {
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
    }
    
    private func header() -> some View {
        ZStack {
            HStack {
                Spacer()
                
                Button {
                    if !risRecords.isEmpty {
                        risRecords.removeAll()
                    }
                    presentRISFilePicker = true
                } label: {
                    Text("Select a RIS file")
                }
                
                Spacer()
            }
            
            HStack {
                Button(action: {
                    dismiss.callAsFunction()
                }, label: {
                    Text("Cancel")
                })
                
                Spacer()
                
                Button(action: {
                    addNewArticle()
                    dismiss.callAsFunction()
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
            newArticle.journal = record.periodicalNameFullFormat ?? record.secondaryTitle
            newArticle.abstract = record.abstract
            newArticle.doi = record.doi
            newArticle.volume = record.volumeNumber
            newArticle.issueNumber = record.issueNumber
            newArticle.startPage = record.startPage
            newArticle.endPage = record.endPage
            newArticle.uuid = UUID()
            
            // Need to parse DA or PY, Y1
            // newArticle.published = Date(from: record.date)
            
            if let date = record.date {
                let splitDate = date.split(separator: "/")
                if splitDate.count > 2 {
                    newArticle.published = getDate(from: splitDate)
                }
            } else if let pulbicationYear = record.pulbicationYear {
                let splitPY = pulbicationYear.split(separator: "/")
                if splitPY.count > 2 {
                    newArticle.published = getDate(from: splitPY)
                }
            } else if let primaryDate = record.primaryDate {
                let splitPrimaryDate = primaryDate.split(separator: "/")
                if splitPrimaryDate.count > 2 {
                    newArticle.published = getDate(from: splitPrimaryDate)
                }
            }
            
            let parseStrategy = PersonNameComponents.ParseStrategy()
            if let primaryAuthor = record.primaryAuthor, let name = try? parseStrategy.parse(primaryAuthor) {
                createAuthorEntity(name, article: newArticle)
            }
            
            if let secondaryAuthor = record.secondaryAuthor, let name = try? parseStrategy.parse(secondaryAuthor) {
                createAuthorEntity(name, article: newArticle)
            }
            
            if let tertiaryAuthor = record.tertiaryAuthor, let name = try? parseStrategy.parse(tertiaryAuthor) {
                createAuthorEntity(name, article: newArticle)
            }
            if let subsidiaryAuthor = record.subsidiaryAuthor, let name = try? parseStrategy.parse(subsidiaryAuthor) {
                createAuthorEntity(name, article: newArticle)
            }
            
            for author in record.authors {
                if let name = try? parseStrategy.parse(author) {
                    createAuthorEntity(name, article: newArticle)
                }
            }
            
            let writer = RISWriter(record: record)
            let ris = RIS(context: viewContext)
            ris.uuid = UUID()
            ris.content = writer.toString()
            ris.article = newArticle
            
        }
        
        viewModel.save(viewContext: viewContext)
        
        risRecords.removeAll()
    }
    
    private func getDate(from yearMonthDate: [String.SubSequence]) -> Date? {
        var date: Date? = nil
        if let year = Int(yearMonthDate[0]), let month = Int(yearMonthDate[1]), let day = Int(yearMonthDate[2]) {
            date = DateComponents(calendar: Calendar(identifier: .iso8601), year: year, month: month, day: day).date
        }
        return date
    }
    
    private func createAuthorEntity(_ authorName: PersonNameComponents, article: Article) -> Void {
        let authorEntity = Author(context: viewContext)
        authorEntity.created = Date()
        authorEntity.uuid = UUID()

        viewModel.populate(author: authorEntity, with: authorName)

        authorEntity.addToArticles(article)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        print("info = \(info)")
        print("info.hasItemsConforming(to: [RISFilePickerViewController.risUTType] = \(info.hasItemsConforming(to: [.text]))")
        if info.hasItemsConforming(to: [.text]) {
            info.itemProviders(for: [.text]).forEach { itemProvider in
                itemProvider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { data, error in
                    guard let data = data else {
                        if let error = error {
                            print("\(error)")
                        }
                        return
                    }
                    
                    print("data = \(data)")
                    
                    if let url = data as? URL, let contents = try? String(contentsOf: url) {
                        risString = contents
                    }
                }
            }
        }
        return true
    }
}

struct AddRISView_Previews: PreviewProvider {
    static var previews: some View {
        AddRISView()
    }
}
