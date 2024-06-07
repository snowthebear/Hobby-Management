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
    

    enum CodingKeys: String, CodingKey {
        case displayName = "displayName"
        case email = "email"
        case storageURL = "storageURL"
        case userListId = "userListId"
    }
}
