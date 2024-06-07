//
//  UserProfile.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 07/06/24.
//

import Foundation

struct UserProfile: Codable {
    var displayName: String
    var email: String
    var storageURL: String
    var userListId: String
    var userID: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "displayName"
        case email = "email"
        case storageURL = "storageURL"
        case userListId = "userListId"
//        case userID
    }
    
    // Adding an initializer to handle userID
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            displayName = try container.decode(String.self, forKey: .displayName)
            email = try container.decode(String.self, forKey: .email)
            storageURL = try container.decode(String.self, forKey: .storageURL)
            userListId = try container.decode(String.self, forKey: .userListId)
            // userID is not decoded because it's not part of the document's fields
        }

        // Use this initializer when creating a UserProfile from Firestore data, passing documentID as userID
        init(displayName: String, email: String, storageURL: String, userListId: String, userID: String) {
            self.displayName = displayName
            self.email = email
            self.storageURL = storageURL
            self.userListId = userListId
            self.userID = userID
        }
}
