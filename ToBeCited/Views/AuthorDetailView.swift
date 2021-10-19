//
//  AuthorDetailView.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 10/19/21.
//

import SwiftUI

struct AuthorDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    var author: Author
    
    var body: some View {
        VStack {
            Text("LAST NAME")
            Text(author.lastName ?? "")
            
            Text("FIRST NAME")
            Text(author.firstName ?? "")
            
            Text("MIDDLE NAME")
            Text(author.middleName ?? "")
            
            Text("NUMBER OF ARTICLES")
            Text("\(author.articles?.count ?? 0)")
        }
    }
}
