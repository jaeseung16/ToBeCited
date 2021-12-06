//
//  RISFilePickerView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/18/21.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct RISFilePickerViewController: UIViewControllerRepresentable {
    static let risUTType = UTType("com.resonance.jlee.ToBeCited.ris")!
    
    @Binding var risString: String
    
    let risParser = RISParser()
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let documentPickerViewController = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.text, RISFilePickerViewController.risUTType])
        
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
        var parent: RISFilePickerViewController
        
        init(_ risFilePickerViewController: RISFilePickerViewController) {
            parent = risFilePickerViewController
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            for url in urls {
                if url.absoluteString.lowercased().contains("ris") {
                    let _ = url.startAccessingSecurityScopedResource()
                    if let risString = try? String(contentsOf: url) {
                        self.parent.risString = risString
                        break
                    }
                    url.stopAccessingSecurityScopedResource()
                }
            }
        }
    }
}
