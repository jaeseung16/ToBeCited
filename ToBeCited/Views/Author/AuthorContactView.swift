//
//  AuthorContactView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 12/1/21.
//

import SwiftUI

struct AuthorContactView: View {
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @State var contact: AuthorContact
    @State var email: String
    @State var institution: String
    @State var address: String
    
    var body: some View {
        VStack {
            HStack {
                Text("EMAIL")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 90, alignment: .leading)
                
                TextField("email", text: $email, prompt: nil)
                    .onSubmit {
                        contact.email = email
                        viewModel.save()
                    }
            }
            
            HStack {
                Text("INSTITUTION")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 90, alignment: .leading)
                
                TextField("institution", text: $institution, prompt: nil)
                    .onSubmit {
                        contact.institution = institution
                        viewModel.save()
                    }
            }
            
            HStack {
                Text("ADDRESS")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 90, alignment: .leading)
                
                TextField("address", text: $address, prompt: nil)
                    .onSubmit {
                        contact.address = address
                        viewModel.save()
                    }
            }
            
            HStack {
                Spacer()
                
                Text("Added on \(ToBeCitedDateFormatter.authorContact.string(from: contact.created ?? Date()))")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
    }
}
