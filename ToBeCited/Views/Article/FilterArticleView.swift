//
//  FilterArticleView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/21/21.
//

import SwiftUI

struct FilterArticleView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Author.lastName, ascending: true)],
        animation: .default)
    private var authors: FetchedResults<Author>
    
    @Binding var author: Author?
    @Binding var publishedIn: Int?
    
    @State private var selectedAuthor = UUID()
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                selectedPublishedView()
                
                selectedAuthorView()
                
                Divider()
                
                HStack {
                    Text("SELECT AN AUTHOR")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                Picker("SELECT AN AUTHOR", selection: $selectedAuthor) {
                    ForEach(authors) { author in
                        if let uuid = author.uuid {
                            Text(viewModel.nameComponents(of: author).formatted(.name(style: .long)))
                                .tag(uuid)
                        }
                    }
                }
                .onChange(of: selectedAuthor) { _ in
                    author = authors.first { $0.uuid == selectedAuthor }
                }
            }
            .padding()
        }
        
    }
    
    private func header() -> some View {
        HStack {
            Button {
                dismiss.callAsFunction()
            } label: {
                Text("Dismiss")
            }

            Spacer()
        }
    }
    
    private func selectedAuthorView() -> some View {
        HStack {
            Text("AUTHOR")
                .font(.caption)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            if author == nil {
                Text("N/A")
                    .foregroundColor(.secondary)
            } else {
                Text("\(viewModel.nameComponents(of: author!).formatted(.name(style: .long)))")
            }
            
            Spacer()
            
            Button {
                author = nil
            } label: {
                Text("reset")
            }
        }
    }
    
    private var yearFormatter: NumberFormatter {
        let dateFormatter = NumberFormatter()
        dateFormatter.numberStyle = .none
        return dateFormatter
    }
    
    private func selectedPublishedView() -> some View {
        HStack {
            Text("PUBLISHED IN")
                .font(.caption)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            TextField("Publication Year", value: $publishedIn, formatter: NumberFormatter(), prompt: Text("N/A"))
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button {
                publishedIn = nil
            } label: {
                Text("reset")
            }
        }
    }
}
