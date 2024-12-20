//
//  TextDocument.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/19/21.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct TextFile: FileDocument {
    static let readableContentTypes = [UTType.plainText]

    var text = ""

    init(initialText: String = "") {
        text = initialText
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}
