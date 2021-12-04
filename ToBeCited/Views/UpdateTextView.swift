//
//  UpdateTextView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/24/21.
//

import SwiftUI

struct UpdateTextView: View {
    @Environment(\.dismiss) private var dismiss
    
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
                    dismiss.callAsFunction()
                } label: {
                    Text("Cancel")
                }

                Spacer()
                
                Button {
                    cancelled = false
                    dismiss.callAsFunction()
                } label: {
                    Text("Done")
                }
            }
        }
        
    }
}

