//
//  AuthorRowView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 11/16/24.
//

import SwiftUI

struct AuthorRowView: View {
    
    @ObservedObject var author: Author
    private var articleCount: Int {
        author.articles?.count ?? 0
    }
    
    var body: some View {
        HStack {
            AuthorNameView(author: author)
            Spacer()
            Label("\(articleCount)", systemImage: "doc.on.doc")
                .font(.callout)
                .foregroundColor(Color.secondary)
        }
    }
}
