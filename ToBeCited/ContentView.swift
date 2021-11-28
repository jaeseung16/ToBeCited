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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(ToBeCitedViewModel.shared)
    }
}
