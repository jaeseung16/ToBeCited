//
//  NotificationTokenHelper.swift
//  ToBeCited
//
//  Created by Jae Seung Lee on 6/12/22.
//

import Foundation
import CoreData
import CloudKit

class NotificationTokenHelper {
    static private let key = "token"
    
    private let appName: String
    
    init(appName: String) {
        self.appName = appName
    }
    
    private func url(for tokenType: NotificationTokenType) -> URL {
        let url = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent(appName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url,
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
            } catch {
                let message = "Could not create persistent container URL for NotificationToken \(tokenType.rawValue)"
                print("\(message): \(error)")
            }
        }
        return url.appendingPathComponent("\(tokenType.rawValue).data", isDirectory: false)
    }
    
    func write(_ token: CKServerChangeToken, for tokenType: NotificationTokenType) throws {
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        coder.encode(token, forKey: NotificationTokenHelper.key)
        let data = coder.encodedData
        try data.write(to: url(for: tokenType))
    }
    
    func read(_ tokenType: NotificationTokenType) throws -> CKServerChangeToken? {
        let data = try Data(contentsOf: url(for: tokenType))
        let coder = try NSKeyedUnarchiver(forReadingFrom: data)
        return coder.decodeObject(of: CKServerChangeToken.self, forKey: NotificationTokenHelper.key)
    }
    
}
