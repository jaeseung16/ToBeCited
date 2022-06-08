//
//  ContentView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/17/21.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var viewModel: ToBeCitedViewModel

    @State private var presentAddRISView = false
    
    var body: some View {
        TabView {
            ArticleListView()
                .tabItem {
                    Label("Articles", systemImage: "doc.on.doc")
                }
            
            AuthorListView()
                .tabItem {
                    Label("Authors", systemImage: "person.3")
                }
            
            CollectionListView()
                .tabItem {
                    Label("Collections", systemImage: "square.stack.3d.up")
                }
        }
        .alert("Failed to save data", isPresented: $viewModel.showAlert) {
            Button("Dismiss") {
                viewModel.showAlert.toggle()
            }
        }
        .onChange(of: viewModel.risString, perform: { _ in
            presentAddRISView = true
        })
        .sheet(isPresented: $presentAddRISView) {
            AddRISView(risString: viewModel.risString)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(viewModel)
        }
    }
}

