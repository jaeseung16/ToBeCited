//
//  AuthorNameView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 12/4/21.
//

import SwiftUI

struct AuthorNameView: View {
    @EnvironmentObject private var viewModel: ToBeCitedViewModel
    
    @State var author: Author
    
    var body: some View {
        Text(viewModel.nameComponents(of: author).formatted(.name(style: .long)))
    }
}
