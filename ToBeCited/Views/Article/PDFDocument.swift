//
//  PDFDocument.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/20/21.
//

import SwiftUI
import UniformTypeIdentifiers

struct PDFFile: FileDocument {
    static var readableContentTypes: [UTType] {
        return [.pdf]
    }
    
    static let writableContentTypes = [UTType.pdf]

    var pdfData = Data()

    init(pdfData: Data = Data()) {
        self.pdfData = pdfData
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.pdfData = data
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: self.pdfData)
    }
}
