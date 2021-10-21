//
//  AddAbstractView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/20/21.
//

import SwiftUI

struct AddAbstractView: View {
    @Environment(\.presentationMode) private var presentationMode
    
    @Binding var abstract: String
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            TextEditor(text: $abstract)
                .disableAutocorrection(true)
                .multilineTextAlignment(.leading)
                .border(Color.secondary)
            
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
    }
    
    private func header() -> some View {
        ZStack {
            HStack {
                Spacer()
                Text("Paste the abstract")
                Spacer()
            }
            
            HStack {
                Button {
                    abstract = ""
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Cancel")
                }
                
                Spacer()
                
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Done")
                }
            }
        }
    }
}
