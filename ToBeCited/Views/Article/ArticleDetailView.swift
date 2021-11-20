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
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @State private var importPdf = false
    @State private var presentPdfView = false
    @State private var presentEditAbstractView = false
    @State private var exportPDF = false
    @State private var pdfData = Data()
    @State private var abstract = ""
    @State private var pdfURL: URL?
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
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
    
    private var references: [Article] {
        var references = [Article]()
        article.references?.forEach { reference in
            if let reference = reference as? Article {
                references.append(reference)
            }
        }
        //print("references.count = \(references.count)")
        return references
    }
    
    private var cited: [Article] {
        var cited = [Article]()
        article.cited?.forEach { article in
            if let article = article as? Article {
                cited.append(article)
            }
        }
        //print("cited.count = \(cited.count)")
        return cited
    }
    
    private var collections: [Collection] {
        var collections = [Collection]()
        article.collections?.forEach { collection in
            if let collection = collection as? Collection {
                collections.append(collection)
            }
        }
        //print("collections.count = \(collections.count)")
        return collections
    }
    
    var body: some View {
        ScrollView {
            VStack {
                header()
                
                /*
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
                */
                
                Divider()
                
                citation()
                
                Divider()
                
                abstractView()
                
                Divider()
                
                referencesView()
                
                citedView()
                
                collectionsView()
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
                //    Text(article.ris?.content ?? "")
                //}
            }
        }
        .navigationTitle(article.title ?? "Title is not available")
        .padding()
        .fileImporter(isPresented: $importPdf, allowedContentTypes: [.pdf]) { result in
            switch result {
            case .success(let url):
                print("pdf url = \(url)")
                if let data = try? Data(contentsOf: url) {
                    self.pdfData = data
                    print("data = \(data)")
                }
            case .failure(let error):
                errorMessage = "Failed to import a pdf file: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
        .fileExporter(isPresented: $exportPDF, documents: [PDFFile(pdfData: pdfData)], contentType: .pdf) { result in
            switch result {
            case .success(_):
                print("success")
                //dismiss.callAsFunction()
            case .failure(let error):
                errorMessage = "Failed to export the pdf file: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
        .alert("ERROR", isPresented: $showErrorAlert) {
            Button("OK") {
                
            }
        } message: {
            Text(errorMessage)
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
                importPdf = true
            } label: {
                Text("Import PDF")
            }
            
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
                if let pdfData = article.pdf {
                    self.pdfData = pdfData
                }
                
                exportPDF = true
            } label: {
                Text("Export PDF")
            }
            .disabled(!pdfExists)
            
            Spacer()
            
            NavigationLink {
                SelectReferencesView(article: article)
            } label: {
                Text("Edit references")
            }
            
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
            title()
            
            Text(journalString)
            
            if article.published != nil {
                Text(publicationDate)
            }
            
            if article.doi != nil, let url = URL(string: "https://dx.doi.org/\(article.doi!)") {
                Link(article.doi!, destination: url)
                    .foregroundColor(.blue)
            }
            
            authorList()
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
                    Text(viewModel.nameComponents(of: author).formatted(.name(style: .long)))
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
    
    private func referencesView() -> some View {
        VStack {
            HStack {
                Text("REFERENCES IMPORTED IN TOBECITED")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            List {
                ForEach(references) { reference in
                    Text(reference.title ?? "No title")
                }
            }
        }
        .frame(height: 200.0)
    }
    
    private func citedView() -> some View {
        VStack {
            HStack {
                Text("ARTICLES CITING THIS ARTICLE IMPORTED IN TOBECITED")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            List {
                ForEach(cited) { cited in
                    Text(cited.title ?? "No title")
                }
            }
        }
        .frame(height: 200.0)
    }
    
    private func collectionsView() -> some View {
        VStack {
            HStack {
                Text("COLLECTIONS")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            List {
                ForEach(collections) { collection in
                    Text(collection.name ?? "No title")
                }
            }
        }
        .frame(height: 200.0)
    }
}

