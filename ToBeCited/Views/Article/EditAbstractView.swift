//
//  AddAbstractView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/20/21.
//

import SwiftUI

struct EditAbstractView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    var article: Article
    @State var abstract: String
    @State private var enableSaveButton = false
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            TextEditor(text: $abstract)
                .onChange(of: abstract, perform: { _ in
                    enableSaveButton = true
                })
                .disableAutocorrection(true)
                .multilineTextAlignment(.leading)
                .lineSpacing(10)
                .border(Color.secondary)
            
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
    }
    
    private func header() -> some View {
        ZStack {
            HStack {
                Spacer()
                Text("Edit Abstract")
                Spacer()
            }
            
            HStack {
                Button {
                    dismiss.callAsFunction()
                } label: {
                    Text("Cancel")
                }
                
                Spacer()
                
                Button {
                    update()
                    dismiss.callAsFunction()
                } label: {
                    Text("Save")
                }
                .disabled(!enableSaveButton)
            }
        }
    }
    
    private func update() -> Void {
        article.abstract = abstract
        viewModel.save(viewContext: viewContext)
    }
}
