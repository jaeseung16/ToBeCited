//
//  PDFFilePickerViewController.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/20/21.
//

import Foundation

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct PDFFilePickerViewController: UIViewControllerRepresentable {
    @Binding var pdfData: Data
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let documentPickerViewController = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        documentPickerViewController.allowsMultipleSelection = false
        documentPickerViewController.delegate = context.coordinator
        return documentPickerViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: PDFFilePickerViewController
        
        init(_ pdfFilePickerViewController: PDFFilePickerViewController) {
            parent = pdfFilePickerViewController
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            for url in urls {
                if url.absoluteString.lowercased().contains("pdf") {
                    if let data = try? Data(contentsOf: url) {
                        self.parent.pdfData = data
                        break
                    }
                }
            }
        }
    }
}
