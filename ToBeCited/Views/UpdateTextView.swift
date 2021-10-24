//
//  UpdateTextView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/24/21.
//

import SwiftUI

struct UpdateTextView: View {
    @Environment(\.presentationMode) private var presentationMode
    
    var title: String
    @Binding var textToUpdate: String
    @Binding var cancelled: Bool
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            TextField("last name", text: $textToUpdate)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
    }
    
    private func header() -> some View {
        ZStack {
            Text(title)
            
            HStack {
                Button {
                    cancelled = true
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Cancel")
                }

                Spacer()
                
                Button {
                    cancelled = false
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Done")
                }
            }
        }
        
    }
}

