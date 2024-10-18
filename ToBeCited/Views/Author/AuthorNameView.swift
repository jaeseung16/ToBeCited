//
//  AuthorNameView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 12/4/21.
//

import SwiftUI

struct AuthorNameView: View {
    @State var author: Author
    
    var body: some View {
        Text(ToBeCitedNameFormatHelper.nameComponents(of: author), format: ToBeCitedNameFormatHelper.format(style: .long))
    }
}
