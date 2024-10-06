//
//  ArticleDetailView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/19/21.
//

import SwiftUI
import UniformTypeIdentifiers

struct ArticleDetailView: View, DropDelegate {
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @State private var importPdf = false
    @State private var presentPdfView = false
    @State private var presentEditAbstractView = false
    @State private var exportPDF = false
    @State private var pdfData = Data()
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var presentAddToCollectionsView = false
    @State private var presentImportCollectionAsReferences = false
    
    var article: Article
    @State var title: String
    @State var published: Date
    
    private var authors: [Author] {
        return article.authors?.compactMap { $0 as? Author } ?? [Author]()
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
        return article.references?.compactMap { $0 as? Article } ?? [Article]()
    }
    
    private var cited: [Article] {
        return article.cited?.compactMap { $0 as? Article } ?? [Article]()
    }
    
    private var collections: [Collection] {
        return article.collections?.compactMap { $0 as? Collection } ?? [Collection]()
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
                viewModel.log("Exported a pdf file to \(url)")
            case .failure(let error):
                errorMessage = "Failed to export the pdf file: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
        .sheet(isPresented: $presentAddToCollectionsView) {
            AddToCollectionsView(article: article)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $presentImportCollectionAsReferences) {
            ImportCollectionAsReferencesView(article: article)
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
        VStack {
            if let ris = article.ris, let content = ris.content {
                HStack {
                    Spacer()
                    
                    Text("RIS")
                    
                    NavigationLink {
                        EditRISView(ris: ris, content: content)
                            .environmentObject(viewModel)
                            .navigationTitle(title)
                    } label: {
                        Label("Edit", systemImage: "pencil.circle")
                    }
                    
                    Spacer()
                }
            }
            
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
                    PDFReadView(pdfData: article.pdf ?? Data())
                        .navigationTitle(title)
                } label: {
                    Label("Open", systemImage: "eye")
                }
                .disabled(!pdfExists)
                
                Spacer()
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
    
    private func updatePDF() -> Void {
        if !pdfData.isEmpty {
            article.pdf = pdfData
            viewModel.save() { success in
                if !success {
                    viewModel.log("Failed to save pdf")
                }
            }
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
                .disableAutocorrection(true)
                .multilineTextAlignment(.center)
                .textFieldStyle(.roundedBorder)
                .padding()
        }
    }
    
    private func updateTitle() -> Void {
        if !title.isEmpty {
            article.title = title
            viewModel.saveAndFetch() { success in
                if !success {
                    viewModel.log("Failed to save title")
                }
            }
        }
    }
    
    private func citation() -> some View {
        VStack {
            titleView()
            
            JournalTitleView(article: article)
            
            publishedView()
        
            if article.doi != nil, let url = URL(string: "https://dx.doi.org/\(article.doi!)") {
                doiLinkView(url: url)
            }
            
            authorList()
        }
    }
    
    private func publishedView() -> some View {
        ZStack {
            HStack {
                #if targetEnvironment(macCatalyst)
                Label("PUBLISHED ON", systemImage: "calendar")
                    .font(.callout)
                    .foregroundColor(.secondary)
                #else
                if UIDevice.current.userInterfaceIdiom == .pad {
                    Label("PUBLISHED ON", systemImage: "calendar")
                        .font(.callout)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "calendar")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                #endif
                
                
                Spacer()
            }
            
            DatePicker("", selection: $published, displayedComponents: [.date])
                .datePickerStyle(DefaultDatePickerStyle())
                .labelsHidden()
                .onChange(of: published) {
                    updatePublished()
                }
        }
    }
    
    private func updatePublished() -> Void {
        article.published = published
        viewModel.save() { success in
            if !success {
                viewModel.log("Failed to save published")
            }
        }
    }
    
    private var publicationDate: String {
        return ToBeCitedDateFormatter.publication.string(from: article.published!)
    }
    
    private func doiLinkView(url: URL) -> some View {
        ZStack {
            HStack {
                #if targetEnvironment(macCatalyst)
                Label("DOI LINK", systemImage: "link")
                    .font(.callout)
                    .foregroundColor(.secondary)
                #else
                if UIDevice.current.userInterfaceIdiom == .pad {
                    Label("DOI LINK", systemImage: "link")
                        .font(.callout)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "link")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                #endif
                
                Spacer()
            }
            
            Link(article.doi!, destination: url)
                .foregroundColor(.blue)
        }
    }
    
    private func authorList() -> some View {
        VStack {
            HStack {
                Label("AUTHORS (unordered)", systemImage: "person.3")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                NavigationLink {
                    EditAuthorsView(article: article, authors: authors)
                        .navigationTitle(title)
                } label: {
                    Label("edit", systemImage: "pencil.circle")
                }
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
                        .environmentObject(viewModel)
                        .navigationTitle(title)
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
                
                NavigationLink {
                    SelectReferencesView(article: article, references: references)
                        .environmentObject(viewModel)
                        .navigationTitle(title)
                } label: {
                    Label("edit", systemImage: "pencil.circle")
                }
                
                Button {
                    viewModel.fetchAllColections()
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
                Label("COLLECTIONS", systemImage: "square.stack.3d.up")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    viewModel.fetchAllColections()
                    presentAddToCollectionsView = true
                } label: {
                    Text("Add to existing collections")
                }
            }
            
            NavigationStack {
                List {
                    ForEach(collections) { collection in
                        NavigationLink(value: collection) {
                            CollectionSummaryRowView(collection: collection)
                        }
                    }
                }
                .navigationDestination(for: Collection.self) { collection in
                    CollectionSummaryView(collection: collection)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle(title)
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

