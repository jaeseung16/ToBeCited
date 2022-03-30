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
                .onOpenURL { url in
                    if url.absoluteString.lowercased().contains("ris") {
                        let _ = url.startAccessingSecurityScopedResource()
                        if let risString = try? String(contentsOf: url) {
                            if !risString.isEmpty {
                                viewModel.risString = risString
                            }
                        }
                        url.stopAccessingSecurityScopedResource()
                    }
                    
                }
        }
    }
}
