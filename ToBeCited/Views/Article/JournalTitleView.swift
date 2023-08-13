//
//  JournalTitleView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 8/13/23.
//

import SwiftUI

struct JournalTitleView: View {
    @State var article: Article
    
    var body: some View {
        Text(ToBeCitedJournalTitleFormatHelper.journalTitle(of: article))
    }
    
}
