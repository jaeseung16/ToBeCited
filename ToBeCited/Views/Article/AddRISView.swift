//
//  AddRISView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/18/21.
//

import SwiftUI
import UniformTypeIdentifiers

struct AddRISView: View, DropDelegate {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @State private var presentRISFilePicker = false
    @State private var risString: String = ""
    @State private var risRecords = [RISRecord]()
    
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
                Button(action: {
                    dismiss.callAsFunction()
                }, label: {
                    Text("Cancel")
                })
                
                Spacer()
                
                Button(action: {
                    addNewArticle()
                    dismiss.callAsFunction()
                }, label: {
                    Text("Save")
                })
            }
        }
    }
    
    private func addNewArticle() {
        if !risString.isEmpty {
            let parser = RISParser()
            if let records = try? parser.parse(risString) {
                for record in records {
                    self.risRecords.append(record)
                }
            }
        }
        
        viewModel.save(risRecords: risRecords, viewContext: viewContext)
        
        risRecords.removeAll()
    }
    
    func performDrop(info: DropInfo) -> Bool {
        print("info = \(info)")
        print("info.hasItemsConforming(to: [RISFilePickerViewController.risUTType] = \(info.hasItemsConforming(to: [.text]))")
        if info.hasItemsConforming(to: [.text]) {
            info.itemProviders(for: [.text]).forEach { itemProvider in
                itemProvider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { data, error in
                    guard let data = data else {
                        if let error = error {
                            print("\(error)")
                        }
                        return
                    }
                    
                    print("data = \(data)")
                    
                    if let url = data as? URL, let contents = try? String(contentsOf: url) {
                        risString = contents
                    }
                }
            }
        }
        return true
    }
}

struct AddRISView_Previews: PreviewProvider {
    static var previews: some View {
        AddRISView()
    }
}
