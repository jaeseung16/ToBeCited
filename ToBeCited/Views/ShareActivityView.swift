//
//  ShareActivityView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/8/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct ShareActivityView: UIViewControllerRepresentable {
    typealias Callback = (_ activityType: UIActivity.ActivityType?, _ completed: Bool, _ returnedItems: [Any]?, _ error: Error?) -> Void
    
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil
    var completionHandler: Callback? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        print("activityItems = \(activityItems)")
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        activityViewController.excludedActivityTypes = excludedActivityTypes
        activityViewController.completionWithItemsHandler = completionHandler
        return activityViewController
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        
    }

}
