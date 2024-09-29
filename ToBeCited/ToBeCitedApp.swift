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
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, appDelegate.persistence.container.viewContext)
                .environmentObject(appDelegate.viewModel)
                .onOpenURL { url in
                    if url.absoluteString.lowercased().contains("ris") {
                        let _ = url.startAccessingSecurityScopedResource()
                        if let risString = try? String(contentsOf: url, encoding: .utf8) {
                            if !risString.isEmpty {
                                appDelegate.viewModel.risString = risString
                            }
                        }
                        url.stopAccessingSecurityScopedResource()
                    }
                }
        }
    }
}
