//
//  StatsView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 3/30/22.
//

import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    var body: some View {
        VStack {
            Text("Number of article: \(viewModel.articleCount)")
            Text("Number of authors: \(viewModel.authorCount)")
        }
    }
}
