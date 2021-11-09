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
    @State private var presentEditAbstractView = false
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
        ScrollView {
            VStack {
                header()
                
                if presentPdfView {
                    VStack {
                        HStack {
                            Button {
                                presentPdfView = false
                            } label: {
                                Text("Dismiss")
                            }
                        }
                        
                        if let url = pdfURL {
                            NavigationLink {
                                PreviewController(url: url)
                            } label: {
                                Text("Open")
                            }
                        }
                    }
                }
                
                
                Divider()
                
                title()
                
                citation()
                
                authorList()
                
                Divider()
                
                abstractView()
                
                Divider()
                /*
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
                */
                //ScrollView {
                    Text(article.ris?.content ?? "")
                //}
            }
        }
        .navigationTitle(article.title ?? "Title is not available")
        .padding()
        .sheet(isPresented: $presentAddPdfView) {
            PDFFilePickerViewController(pdfData: $pdfData)
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
            VStack {
                HStack {
                    Button {
                        presentPdfView = false
                    } label: {
                        Text("Dismiss")
                    }
                }
                
                //PDFKitView(pdfData: article.pdf!)
                if let url = pdfURL {
                    PreviewController(url: url)
                }
            }
        }
         */
    }
    
    private func header() -> some View {
        HStack {
            Spacer()
            
            Button {
                presentAddPdfView = true
            } label: {
                Text("Add pdf")
            }
            .disabled(pdfExists)
            
            Button {
                if let title = article.title, let pdfData = article.pdf {
                    if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let fileURL = url.appendingPathComponent("\(title).pdf", isDirectory: false)
                        
                        do {
                            try pdfData.write(to: fileURL)
                        } catch {
                            print("Failed to save the csv file")
                        }
                        
                        pdfURL = fileURL
                        print("pdfURL = \(String(describing: pdfURL))")
                    }
                }
                presentPdfView = true
            } label : {
                Text("Open pdf")
            }
            .disabled(!pdfExists)
            
            Button {
                if let title = article.title, let pdfData = article.pdf {
                    if let url = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
                        let fileURL = url.appendingPathComponent("\(title).pdf", isDirectory: false)
                        
                        do {
                            try pdfData.write(to: fileURL)
                        } catch {
                            print("Failed to save the pdf file")
                        }
                        
                        pdfURL = fileURL
                    }
                }
                print("pdfURL = \(String(describing: pdfURL))")
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
            
            Spacer()
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
    
    private func title() -> some View {
        VStack {
            HStack {
                Text("TITLE")
                    .font(.callout)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Text(article.title ?? "Title is not available")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
    
    private func citation() -> some View {
        VStack {
            Text(journalString)
            
            if article.published != nil {
                Text(publicationDate)
            }
            
            if article.doi != nil, let url = URL(string: "https://dx.doi.org/\(article.doi!)") {
                Link(article.doi!, destination: url)
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }

    private var journalString: String {
        guard let journalTitle = article.journal else {
            return "Journal title is not available"
        }
        
        return journalTitle + " " + (article.volume ?? "") + ", " + (article.page ?? "")
    }
    
    private var publicationDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: article.published!)
    }
    
    private func authorList() -> some View {
        VStack {
            HStack {
                Text("AUTHORS (unordered)")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            ForEach(authors, id: \.uuid) { author in
                HStack {
                    Spacer()
                    Text(name(of: author))
                    Spacer()
                }
            }
        }
    }
    
    private func name(of author: Author) -> String {
        guard let lastName = author.lastName, let firstName = author.firstName else {
            return "The name of an author is not available"
        }
        
        let middleName = author.middleName == nil ? " " : " \(author.middleName!) "
        
        return firstName + middleName + lastName
    }
    
    private func abstractView() -> some View {
        VStack {
            HStack {
                Text("ABSTRACT")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                NavigationLink {
                    EditAbstractView(article: article, abstract: article.abstract ?? "")
                } label: {
                    Label("edit", systemImage: "pencil.circle")
                }
            }
            
            if abstractExists {
                Text(article.abstract!)
                    .padding()
            } else {
                Text("No Abstract")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
}

