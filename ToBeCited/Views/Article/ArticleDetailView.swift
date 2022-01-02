//
//  ArticleDetailView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/19/21.
//

import SwiftUI
import UniformTypeIdentifiers

struct ArticleDetailView: View, DropDelegate {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @State private var importPdf = false
    @State private var presentPdfView = false
    @State private var presentEditAbstractView = false
    @State private var exportPDF = false
    @State private var pdfData = Data()
    @State private var pdfURL: URL?
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var presentSelectReferenceView = false
    @State private var presentAddToCollectionsView = false
    @State private var presentImportCollectionAsReferences = false
    
    var article: Article
    @State var title: String
    
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
        return references
    }
    
    private var cited: [Article] {
        var cited = [Article]()
        article.cited?.forEach { article in
            if let article = article as? Article {
                cited.append(article)
            }
        }
        return cited
    }
    
    private var collections: [Collection] {
        var collections = [Collection]()
        article.collections?.forEach { collection in
            if let collection = collection as? Collection {
                collections.append(collection)
            }
        }
        return collections
    }
    
    var body: some View {
        ScrollView {
            VStack {
                header()
                    .onDrop(of: [.pdf], delegate: self)
                
                Divider()
                
                citation()
                
                Divider()
                
                abstractView()
                
                Divider()
                
                referencesView()
                
                citedView()
                
                collectionsView()
            }
        }
        .navigationTitle(title)
        .padding()
        .fileImporter(isPresented: $importPdf, allowedContentTypes: [.pdf]) { result in
            switch result {
            case .success(let url):
                let _ = url.startAccessingSecurityScopedResource()
                if let data = try? Data(contentsOf: url) {
                    pdfData = data
                    updatePDF()
                }
                url.stopAccessingSecurityScopedResource()
            case .failure(let error):
                errorMessage = "Failed to import a pdf file: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
        .fileExporter(isPresented: $exportPDF, documents: [PDFFile(pdfData: pdfData)], contentType: .pdf) { result in
            switch result {
            case .success(let url):
                print("saved pdf at \(url)")
            case .failure(let error):
                errorMessage = "Failed to export the pdf file: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
        .sheet(isPresented: $presentSelectReferenceView) {
            SelectReferencesView(article: article, references: references)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $presentAddToCollectionsView) {
            AddToCollectionsView(article: article)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $presentImportCollectionAsReferences) {
            ImportCollectionAsReferencesView(article: article)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(viewModel)
        }
        .alert("ERROR", isPresented: $showErrorAlert) {
            Button("OK") {
                
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func header() -> some View {
        HStack {
            Spacer()
            
            Text("PDF")
            
            Button {
                importPdf = true
            } label: {
                Label("Import", systemImage: "square.and.arrow.down")
            }
            
            Button {
                if let pdfData = article.pdf {
                    self.pdfData = pdfData
                }
                
                exportPDF = true
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .disabled(!pdfExists)
            
            NavigationLink {
                PDFKitView(pdfData: article.pdf ?? Data())
                    .navigationTitle(title)
            } label: {
                Label("Open", systemImage: "eye")
            }
            .disabled(!pdfExists)
            
            Spacer()
        }
        .fixedSize(horizontal: false, vertical: true)
    }
    
    private func updatePDF() -> Void {
        if !pdfData.isEmpty {
            article.pdf = pdfData
            viewModel.save(viewContext: viewContext)
        }
    }
    
    private func titleView() -> some View {
        VStack {
            HStack {
                Text("TITLE")
                    .font(.callout)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            TextField("title", text: $title)
                .onSubmit {
                    updateTitle()
                }
                .font(.title2)
                .multilineTextAlignment(.center)
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundColor(.secondary)
                }
                .padding()
        }
    }
    
    private func updateTitle() -> Void {
        if !title.isEmpty {
            article.title = title
            viewModel.save(viewContext: viewContext)
        }
    }
    
    private func citation() -> some View {
        VStack {
            titleView()
            
            Text(viewModel.journalString(article: article))
            
            if article.published != nil {
                Text(publicationDate)
                    .font(.callout)
            }
            
            if article.doi != nil, let url = URL(string: "https://dx.doi.org/\(article.doi!)") {
                Link(article.doi!, destination: url)
                    .foregroundColor(.blue)
            }
            
            authorList()
        }
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
                    AuthorNameView(author: author)
                }
            }
        }
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
                Text("\(references.count) REFERENCES IMPORTED IN TOBECITED")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    presentSelectReferenceView = true
                } label: {
                    Label("edit", systemImage: "pencil.circle")
                }
                
                Button {
                    presentImportCollectionAsReferences = true
                } label: {
                    Label("import from collections", systemImage: "square.and.arrow.down.on.square")
                }
            }
            
            List {
                ForEach(references) { reference in
                    NavigationLink {
                        ArticleSummaryView(article: reference)
                    } label: {
                        ArticleRowView(article: reference)
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .frame(height: 200.0)
    }
    
    private func citedView() -> some View {
        VStack {
            HStack {
                Text("\(cited.count) ARTICLES CITING THIS ARTICLE IMPORTED IN TOBECITED")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            List {
                ForEach(cited) { cited in
                    NavigationLink {
                        ArticleSummaryView(article: cited)
                    } label: {
                        ArticleRowView(article: cited)
                    }
                }
            }
            .listStyle(PlainListStyle())
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
                
                Button {
                    presentAddToCollectionsView = true
                } label: {
                    Text("Add to existing collections")
                }
            }
            
            List {
                ForEach(collections) { collection in
                    NavigationLink {
                        CollectionSummaryView(collection: collection)
                    } label: {
                        HStack {
                            Text(collection.name ?? "No title")
                            Spacer()
                            Text(collection.created ?? Date(), style: .date)
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .frame(height: 200.0)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        if info.hasItemsConforming(to: [.pdf]) {
            info.itemProviders(for: [.pdf]).forEach { itemProvider in
                itemProvider.loadItem(forTypeIdentifier: UTType.pdf.identifier, options: nil) { url, error in
                    guard let url = url as? URL else {
                        if let error = error {
                            errorMessage = error.localizedDescription
                            showErrorAlert = true
                        }
                        return
                    }

                    let _ = url.startAccessingSecurityScopedResource()
                    if let data = try? Data(contentsOf: url) {
                        self.pdfData = data
                        self.updatePDF()
                    }
                    url.stopAccessingSecurityScopedResource()
                }
            }
        }
        return true
    }
}

