//
//  NotificationToken.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 6/8/22.
//

import Foundation
import CoreData
import CloudKit

enum NotificationToken: String {
    static private let key = "token"
    
    case server, zone
    
    var url: URL {
        let url = NSPersistentContainer.defaultDirectoryURL()
            .appendingPathComponent(ToBeCitedConstants.appName.rawValue, isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url,
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
            } catch {
                let message = "Could not create persistent container URL for NotificationToken \(self.rawValue)"
                print("\(message): \(error)")
            }
        }
        return url.appendingPathComponent("\(self.rawValue).data", isDirectory: false)
    }
    
    func write(_ token: CKServerChangeToken) throws {
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        coder.encode(token, forKey: NotificationToken.key)
        let data = coder.encodedData
        try data.write(to: url)
    }
    
    func readToken() throws -> CKServerChangeToken? {
        let data = try Data(contentsOf: url)
        let coder = try NSKeyedUnarchiver(forReadingFrom: data)
        return coder.decodeObject(of: CKServerChangeToken.self, forKey: NotificationToken.key)
    }
    
}
