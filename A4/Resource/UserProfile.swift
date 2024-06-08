//
//  UserProfile.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 07/06/24.
//

import Foundation

/**
 UserProfile represents a user's profile information, including display name, email, storage URL, user list ID, user ID, and user hobbies.
 */
struct UserProfile: Codable {
    var displayName: String
    var email: String
    var storageURL: String
    var userListId: String?
    var userID: String?
    var userHobby: [Hobby]?

    enum CodingKeys: String, CodingKey {
        case displayName = "displayName"
        case email = "email"
        case storageURL = "storageURL"
        case userListId = "userListId"
    }
    
    // The coding keys for encoding and decoding the UserProfile properties
    // Adding an initializer to handle userID
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        displayName = try container.decode(String.self, forKey: .displayName)
        email = try container.decode(String.self, forKey: .email)
        storageURL = try container.decode(String.self, forKey: .storageURL)
        userListId = try container.decode(String.self, forKey: .userListId)
    }

    /**
     Initializes a new UserProfile instance from a decoder.
     - Parameters:
       - decoder: The decoder to decode data from.
     - Throws: An error if any values are missing or if the data is corrupted.
     */
    init(displayName: String, email: String, storageURL: String, userListId: String?, userHobby: [Hobby]?, userID: String) {
        // Use this initializer when creating a UserProfile from Firestore data, passing documentID as userID
        self.displayName = displayName
        self.email = email
        self.storageURL = storageURL
        self.userListId = userListId
        self.userID = userID
        self.userHobby = userHobby
    }
}
