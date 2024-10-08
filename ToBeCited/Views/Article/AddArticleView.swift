//
//  AddArticleView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/17/21.
//

import SwiftUI

struct AddArticleView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    
    @State private var journal: String = ""
    @State private var volume: String = ""
    @State private var number: String = ""
    @State private var pages: String = ""
    
    @State private var published: Date = Date()
    
    @State private var doi: String = ""
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            titleView()
            
            journalView()
            
            DatePicker("PUBLISHED", selection: $published, displayedComponents: [.date])

            doiView()
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
        
    }
    
    private func header() -> some View {
        ZStack {
            HStack {
                Spacer()
                Text("Add an article")
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
                    dismiss.callAsFunction()
                } label: {
                    Text("Save")
                }
            }
        }
    }
    
    private func titleView() -> some View {
        VStack(alignment: .leading) {
            Text("TITLE")
            TextField("Title", text: $title)
                .multilineTextAlignment(.trailing)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
        }
    }
    
    private func journalView() -> some View {
        VStack(alignment: .leading) {
            Text("JOURNAL")
            TextField("journal", text: $title)
                .multilineTextAlignment(.trailing)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            
            Text("VOLUME")
            TextField("volume", text: $title)
                .multilineTextAlignment(.trailing)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            
            Text("NUMBER")
            TextField("number", text: $title)
                .multilineTextAlignment(.trailing)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            
            Text("PAGES")
            TextField("pages", text: $title)
                .multilineTextAlignment(.trailing)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
        }
    }
    
    private func doiView() -> some View {
        VStack(alignment: .leading) {
            Text("DOI")
            TextField("doi", text: $doi)
                .multilineTextAlignment(.trailing)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
        }
    }
    
}
