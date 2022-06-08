//
//  ToBeCitedApp.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/17/21.
//

import SwiftUI
import Persistence

@main
struct ToBeCitedApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate 
    
    var body: some Scene {
        let persistence = Persistence(name: ToBeCitedConstants.appName.rawValue, identifier: ToBeCitedConstants.iCloudIdentifier.rawValue)
        let viewModel = ToBeCitedViewModel(persistence: persistence)

        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
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
