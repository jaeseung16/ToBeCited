//
//  ExportCollectionView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/15/21.
//

import SwiftUI

struct ExportCollectionView: View {    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    var collection: Collection
    
    @State private var exportOrder: ExportOrder = .dateEnd
    @State private var showFileExporter = false
    @State private var showErrorAlert = false
    
    private var articles: [Article] {
        collection.orders?
            .map { $0 as! OrderInCollection }
            .sorted(by: { $0.order < $1.order })
            .map { $0.article }
            .filter { $0 != nil }
            .map { $0! } ?? [Article]()
    }
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            templatePickerView()
            
            TextEditor(text: $viewModel.stringToExport)
                .lineSpacing(10)
                .frame(height: 300)
        }
        .fileExporter(isPresented: $showFileExporter, documents: [TextFile(initialText: viewModel.stringToExport)], contentType: .plainText) { result in
            switch result {
            case .success(_):
                dismiss.callAsFunction()
            case .failure(_):
                showErrorAlert = true
            }
        }
        .alert("ERROR", isPresented: $showErrorAlert) {
            Button("OK") {
                dismiss.callAsFunction()
            }
        } message: {
            Text("Failed to export \(collection.name ?? "")")
        }
        .padding()
        
    }
    
    private func header() -> some View {
        HStack {
            Button {
                dismiss.callAsFunction()
            } label: {
                Text("Cancel")
            }
        
            Spacer()
            
            Button {
                showFileExporter = true
            } label: {
                Text("Export")
            }
            
        }
    }
    
    private func stringToExport(for risContent: String) -> String {
        if let ris = viewModel.parse(risString: risContent), !ris.isEmpty {
            return ris[0].description
        }
        return ""
    }
    
    private func templatePickerView() -> some View {
        VStack {
            Text("Selected: \(exportOrder.description)")
            Picker("", selection: $exportOrder) {
                ForEach(ExportOrder.allCases) {
                    Text($0.description)
                        .tag($0)
                }
            }
            .pickerStyle(InlinePickerStyle())
            .onChange(of: exportOrder) { _ in
                viewModel.export(collection: collection, with: exportOrder)
            }
        }
    }
}

