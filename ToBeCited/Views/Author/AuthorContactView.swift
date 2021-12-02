//
//  AuthorContactView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 12/1/21.
//

import SwiftUI

struct AuthorContactView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @State var contact: AuthorContact
    @State var email: String
    @State var institution: String
    @State var address: String
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                Text("Added on \(dateFormatter.string(from: contact.created ?? Date()))")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("EMAIL")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 90, alignment: .leading)
                
                TextField("email", text: $email, prompt: nil)
                    .onSubmit {
                        contact.email = email
                        viewModel.save(viewContext: viewContext)
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
                        viewModel.save(viewContext: viewContext)
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
                        viewModel.save(viewContext: viewContext)
                    }
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter
    }
}
