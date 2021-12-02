//
//  AddContactView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/24/21.
//

import SwiftUI

struct AddContactView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @State var author: Author
    @State private var email = ""
    @State private var institution = ""
    @State private var address = ""
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            Text("E-Mail Address")
            
            TextField("email", text: $email)
                .keyboardType(.emailAddress)
            
            Text("Institution")
            
            TextField("institution", text: $institution)
            
            Text("Address")
            
            TextField("address", text: $address)
            
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
                saveContact()
                dismiss.callAsFunction()
            } label: {
                Text("Save")
            }
            .disabled(email.isEmpty && institution.isEmpty && address.isEmpty)
        }
    }
    
    private func saveContact() -> Void {
        let contact = AuthorContact(context: viewContext)
        contact.created = Date()
        contact.email = email
        contact.institution = institution
        contact.address = address
        
        author.addToContacts(contact)
        viewModel.save(viewContext: viewContext)
    }
}
