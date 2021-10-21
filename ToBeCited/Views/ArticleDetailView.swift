//
//  ArticleDetailView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/19/21.
//

import SwiftUI

struct ArticleDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var presentAddPdfView = false
    @State private var presentPdfView = false
    @State private var presentAddAbstractView = false
    @State private var sharePDF = false
    @State private var pdfData = Data()
    @State private var abstract = ""
    @State private var pdfURL: URL?
    
    var article: Article
    
    private var authors: [Author] {
        var authors = [Author]()
        article.authors?.forEach { author in
            if let author = author as? Author {
                authors.append(author)
            }
        }
        return authors
    }
    
    private var abstractExists: Bool {
        if let abstract = article.abstract {
            return !abstract.isEmpty
        } else {
            return false
        }
    }
    
    private var pdfExists: Bool {
        if let pdf = article.pdf {
            return !pdf.isEmpty
        } else {
            return false
        }
    }
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            Text(article.title ?? "title")
            
            Text(article.journal ?? "journal")
            
            if abstractExists {
                Text(article.abstract!)
            } else {
                Text(abstract)
            }
            
            if article.doi != nil, let url = URL(string: "https://dx.doi.org/\(article.doi!)") {
                Link(article.doi!, destination: url)
            }
            
            List {
                ForEach(authors, id: \.uuid) { author in
                    HStack {
                        Text(author.lastName ?? "last name")
                        Spacer()
                        Text(author.firstName ?? "first name")
                        Spacer()
                        Text(author.middleName ?? "middle name")
                    }
                }
            }
            
            Divider()
            
            if article.pdf != nil {
                PDFKitView(pdfData: article.pdf!)
                    .scaledToFit()
                /*
                 Button {
                 presentPdfView = true
                 } label: {
                 
                 }
                 */
            } else if !pdfData.isEmpty {
                PDFKitView(pdfData: pdfData)
                    .scaledToFit()
            }
            
            /*
             ScrollView {
             Text(article.ris?.content ?? "")
             }
             */
            
        }
        .padding()
        .sheet(isPresented: $presentAddPdfView) {
            PDFFilePickerViewController(pdfData: $pdfData)
        }
        .sheet(isPresented: $presentAddAbstractView) {
            AddAbstractView(abstract: $abstract)
        }
        .sheet(isPresented: $sharePDF) {
            if let url = pdfURL {
                ShareActivityView(activityItems: [url], applicationActivities: nil, excludedActivityTypes: nil, completionHandler: { _, completed, _, error in
                    if completed {
                        sharePDF = false
                    }
                })
            }
        }
        /*
         .sheet(isPresented: $presentPdfView) {
         PDFKitView(pdfData: article.pdf!)
         }
         */
    }
    
    private func header() -> some View {
        HStack {
            Button {
                presentAddPdfView = true
            } label: {
                Text("Add pdf")
            }
            .disabled(pdfExists)
            
            Spacer()
            
            Button {
                presentAddAbstractView = true
            } label : {
                Text("Add abstract")
            }
            .disabled(abstractExists)
            
            Spacer()
            
            Button {
                if let title = article.title, let pdfData = article.pdf {
                    if let url = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
                        let fileURL = url.appendingPathComponent("\(title).pdf", isDirectory: false)
                        
                        do {
                            try pdfData.write(to: fileURL)
                        } catch {
                            print("Failed to save the csv file")
                        }
                        
                        pdfURL = fileURL
                    }
                }
                print("pdfURL = \(pdfURL)")
                sharePDF = true
            } label: {
                Text("Share pdf")
            }
            .disabled(!pdfExists)
            
            
            Spacer()
            
            Button {
                update()
            } label: {
                Text("Save")
            }
            .disabled(self.abstract.isEmpty && pdfData.isEmpty)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
    
    private func update() -> Void {
        if !self.abstract.isEmpty {
            self.article.abstract = self.abstract
        }
        
        if !self.pdfData.isEmpty {
            self.article.pdf = self.pdfData
        }
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        self.abstract = ""
    }
}

