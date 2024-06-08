//
//  UserManager.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 05/05/24.
//

import Foundation
import FirebaseAuth

/**
 UserManager is a singleton class that manages the current user's information, including authentication, user data, user lists, and access tokens.
 */
class UserManager {
    static let shared = UserManager() // shared instance of `UserManager` for singleton access
    var currentUser: FirebaseAuth.User? // current authenticated Firebase user
    var userData: [String: Any]? // dictionary to store additional user data
    var currentUserList: UserList? // current user's list of hobbies
    var accessToken: String? // the access token for the current user

    private init() {}
    
}
