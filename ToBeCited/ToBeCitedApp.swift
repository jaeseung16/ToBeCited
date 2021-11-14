//
//  ToBeCitedApp.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/17/21.
//

import SwiftUI

@main
struct ToBeCitedApp: App {
    let persistenceController = PersistenceController.shared
    let viewModel = ToBeCitedViewModel.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(viewModel)
        }
    }
}
