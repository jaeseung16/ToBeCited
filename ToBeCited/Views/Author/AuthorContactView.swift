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
                Text("EMAIL")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 90, alignment: .leading)
                
                TextField("email", text: $email, prompt: nil)
                    .onSubmit {
                        viewContext.perform {
                            contact.email = email
                            
                            Task {
                                do {
                                    try await viewModel.save()
                                } catch {
                                    viewModel.log("Failed to save email: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
            }
            
            HStack {
                Text("INSTITUTION")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 90, alignment: .leading)
                
                TextField("institution", text: $institution, prompt: nil)
                    .onSubmit {
                        viewContext.perform {
                            contact.institution = institution
                            
                            Task {
                                do {
                                    try await viewModel.save()
                                } catch {
                                    viewModel.log("Failed to save institution: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
            }
            
            HStack {
                Text("ADDRESS")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 90, alignment: .leading)
                
                TextField("address", text: $address, prompt: nil)
                    .onSubmit {
                        viewContext.perform {
                            contact.address = address
                            
                            Task {
                                do {
                                    try await viewModel.save()
                                } catch {
                                    viewModel.log("Failed to save address: \(error.localizedDescription)")
                                }
                            }
                        }
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
