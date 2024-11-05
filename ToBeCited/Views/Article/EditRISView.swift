//
//  EditRISView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 1/2/22.
//

import SwiftUI

struct EditRISView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    var ris: RIS
    @State var content: String
    @State private var enableSaveButton = false
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            TextEditor(text: $content)
                .onChange(of: content) {
                    enableSaveButton = true
                }
                .disableAutocorrection(true)
                .multilineTextAlignment(.leading)
                .lineSpacing(10)
                .border(Color.secondary)
            
        }
        .frame(maxHeight: .infinity, alignment: .top)
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
                update()
                dismiss.callAsFunction()
            } label: {
                Text("Save")
            }
            .disabled(!enableSaveButton)
        }
    }
    
    private func update() -> Void {
        viewContext.perform {
            ris.content = content

            Task {
                do {
                    try await viewModel.save()
                } catch {
                    viewModel.log("Failed to update RIS: \(error.localizedDescription)")
                }
            }
            
            viewModel.fetchAll()
        }
    }
}
