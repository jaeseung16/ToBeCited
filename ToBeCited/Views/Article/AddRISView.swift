//
//  AddRISView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/18/21.
//

import SwiftUI
import UniformTypeIdentifiers

struct AddRISView: View, DropDelegate {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @State private var presentRISFilePicker = false
    @State var risString: String = ""
    @State private var risRecords = [RISRecord]()
    @State private var showAlert = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                if risString.isEmpty {
                    Image(systemName: "doc.text")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 0.2 * geometry.size.width)
                        .onDrop(of: [RISFilePickerViewController.risUTType, .text], delegate: self)
                } else {
                    TextEditor(text: $risString)
                        .lineSpacing(10)
                }
                
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding()
            .sheet(isPresented: $presentRISFilePicker) {
                RISFilePickerViewController(risString: $risString)
                    .environmentObject(viewModel)
            }
            .alert("Failed to open RIS file", isPresented: $showAlert) {
                Button("Dismiss", role: .cancel) {
                    //
                }
            }
        }
    }
    
    private func header() -> some View {
        ZStack {
            HStack {
                Spacer()
                
                Button {
                    if !risRecords.isEmpty {
                        risRecords.removeAll()
                    }
                    presentRISFilePicker = true
                } label: {
                    Text("Select a RIS file")
                }
                
                Spacer()
            }
            
            HStack {
                Button {
                    dismissView()
                } label: {
                    Text("Cancel")
                }

                Spacer()
                
                Button {
                    Task {
                        await addNewArticle()
                    }
                } label: {
                    Text("Save")
                }
            }
        }
    }
    
    private func addNewArticle() async {
        if !risString.isEmpty {
            if let records = await viewModel.parse(risString: risString) {
                for record in records {
                    self.risRecords.append(record)
                }
            }
        }
        
        viewModel.save(risRecords: risRecords)
        
        risRecords.removeAll()
        
        dismissView()
    }
    
    private func dismissView() -> Void {
        viewModel.risString = ""
        dismiss.callAsFunction()
    }
    
    func performDrop(info: DropInfo) -> Bool {
        if info.hasItemsConforming(to: [.text]) {
            info.itemProviders(for: [.text]).forEach { itemProvider in
                // TODO: Use the corresponding asynchronous method?
                itemProvider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { data, error in
                    guard let data = data else {
                        Task {
                            await MainActor.run {
                                showAlert.toggle()
                            }
                        }
                        return
                    }
                    
                    if let url = data as? URL {
                        let _ = url.startAccessingSecurityScopedResource()
                        if let contents = try? String(contentsOf: url, encoding: .utf8) {
                            Task {
                                await MainActor.run {
                                    risString = contents
                                }
                            }
                        }
                        url.stopAccessingSecurityScopedResource()
                    }
                }
            }
        }
        return true
    }
}
