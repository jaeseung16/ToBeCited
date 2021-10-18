//
//  AddRISView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/18/21.
//

import SwiftUI

struct AddRISView: View {
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var presentRISFilePicker = false
    @State private var risString: String = ""
    @State private var risRecords = [RISRecord]()
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            Text(risString)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
        .sheet(isPresented: $presentRISFilePicker) {
            RISFilePickerViewController(risString: $risString)
        }
    }
    
    private func header() -> some View {
        ZStack {
            HStack {
                Spacer()
                
                Button {
                    presentRISFilePicker = true
                } label: {
                    Text("Select a RIS file")
                }
                
                Spacer()
            }
            
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("Cancel")
                })
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("Done")
                })
            }
        }
    }
}

struct AddRISView_Previews: PreviewProvider {
    static var previews: some View {
        AddRISView()
    }
}
