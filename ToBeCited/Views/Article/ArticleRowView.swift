//
//  ArticleRowView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 12/3/21.
//

import SwiftUI

struct ArticleRowView: View {
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @State var article: Article
    
    var body: some View {
        VStack {
            HStack {
                Text(article.title ?? "N/A")
                Spacer()
            }
            
            HStack {
                Spacer()
                
                Text(viewModel.journalString(article: article))
                
                Spacer()
                    .frame(width: 10)
                
                Text("\(viewModel.yearOnlyDateFormatter.string(from: article.published ?? Date()))")
            }
            .font(.callout)
            .foregroundColor(.secondary)
        }
    }
}
