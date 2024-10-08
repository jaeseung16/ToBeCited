//
//  AuthorMergeView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/21/21.
//

import SwiftUI

struct AuthorMergeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    var authors: [Author]
    
    @State private var selected: [Author] = [Author]()
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            List {
                ForEach(selected) { author in
                    HStack {
                        AuthorNameView(author: author)
                        Spacer()
                        Text("\(author.articles?.count ?? 0)")
                    }
                }
            }
            Divider()
            
            List {
                ForEach(authors) { author in
                    Button {
                        if selected.contains(author), let index = selected.firstIndex(of: author) {
                            selected.remove(at: index)
                        } else {
                            selected.append(author)
                        }
                    } label: {
                        HStack {
                            AuthorNameView(author: author)
                            Spacer()
                            Text("\(author.articles?.count ?? 0)")
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    private func header() -> some View {
        HStack {
            Button {
                dismiss.callAsFunction()
            } label: {
                Text("Done")
            }
            
            Spacer()
            
            Button {
                viewModel.merge(authors: selected)
                dismiss.callAsFunction()
            } label: {
                Text("Merge")
            }
            .disabled(selected.count < 2)

        }
    }
    
}


