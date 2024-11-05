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
        TabView(selection: $viewModel.selectedTab) {
            Tab("Articles", systemImage: "doc.on.doc", value: .articles) {
                ArticleListView()
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(viewModel)
            }
            
            Tab("Authors", systemImage: "person.3", value: .authors) {
                AuthorListView()
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(viewModel)
            }
            
            Tab("Collections", systemImage: "square.stack.3d.up", value: .collections) {
                CollectionListView()
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(viewModel)
            }
        }
        .alert("Failed to save data", isPresented: $viewModel.showAlert) {
            Button("Dismiss", role: .cancel) {
                //
            }
        }
        .onChange(of: viewModel.risString) {
            presentAddRISView = !viewModel.risString.isEmpty
        }
        .sheet(isPresented: $presentAddRISView) {
            AddRISView(risString: viewModel.risString)
                .environmentObject(viewModel)
        }
    }
}

