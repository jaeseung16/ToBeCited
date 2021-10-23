//
//  PDFKitView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/20/21.
//

import SwiftUI
import PDFKit

struct PDFKitView: UIViewRepresentable {
    @State var pdfData: Data
    
    func makeUIView(context: Context) -> PDFView {
        print("pdfData = \(pdfData)")
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: pdfData)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        return pdfView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        print("pdfData = \(pdfData)")
        uiView.document = PDFDocument(data: pdfData)
    }
}
