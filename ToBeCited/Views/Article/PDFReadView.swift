//
//  PDFView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/1/24.
//

import SwiftUI

struct PDFReadView: View {
    @Environment(\.dismiss) var dismiss
    
    @State var pdfData: Data
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                PDFKitView(pdfData: pdfData)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss.callAsFunction()
                    } label: {
                        Label("Dismiss", systemImage: "xmark.square")
                    }
                }
            }
        }

    }
}
