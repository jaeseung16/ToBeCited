//
//  PDFDocument.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/20/21.
//

import SwiftUI
import UniformTypeIdentifiers

struct PDFFile: FileDocument {
    // tell the system we support only plain text
    static var readableContentTypes = [UTType.pdf]
    static var writableContentTypes = [UTType.pdf]

    // by default our document is empty
    var pdfData = Data()

    // a simple initializer that creates new, empty documents
    init(pdfData: Data = Data()) {
        self.pdfData = pdfData
    }

    // this initializer loads data that has been saved previously
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.pdfData = data
        }
    }

    // this will be called when the system wants to write our data to disk
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        print("fileWrapper: data = \(self.pdfData)")
        return FileWrapper(regularFileWithContents: self.pdfData)
    }
}
